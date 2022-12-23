---
title: 在分布式系统使用Kafka
date: 2020-05-12 12:30:00
tags:
- 系统设计
categories:
- 语言
- Go
---

在分布式系统中，常常使用消息系统进行系统解耦，并实现一些异步业务逻辑，保证系统最终数据一致性。这里主要介绍在实际中落地使用 Kafka 的一些事项。

![预览图](//www.fanhaobai.com/2020/05/use-kafka/1589262505081.png)<!--more-->

## 消息TOPIC

根据不同业务，拆分不同的 Topic。

## 消息结构

### 格式定义

推送至 Kafka 的消息统一使用 JSON 结构，数据如：

```Json
{
"type": "/StatusEvent",
"data": "XXXXXXXXXX"
}
```


消息结构定义为：

```Go
// 消息事件数据
type PbEventMessage struct {
   // 事件数据类型：包/结构体名
   Type string
   // 事件数据
   Data []byte
}
```

其中，`Type` 为消息类型，`Type` 为消息事件的 PB 结构体名称；`Data` 为 PB 协议的事件数据，见下文。

> 由于 PB 只序列化字段类型和顺序，因此同一个 PB 数据流在反序列化时，存在多个类型消息事件解释。而同一个 Topic 会存在多个类型消息事件，只通过 PB 并不能区分消息，因此引入 Type 用来区分不同类型消息。


### 事件数据

例如，当业务订单状态发生扭转时，会产生订单状态事件消息。

```
订单状态
message StatusEvent {
    // 订单transNo
    uint64 trans_no = 1;
    // 状态
    uint32 status = 2;
    // 扩展数据
    string ext = 3;
}
```


## 业务消费

通过消费 Kafka 消息，实现部分业务逻辑。在实现 Consume 时，需要注意以下几个事项：

1、原则上保持职责单一原则

即不同的业务逻辑要拆分到不同的 Consume 实现。

```Go
// Consume PaySms
// 支付短信提醒
type PaySms struct {
   handler.Base
}


func (h PaySms) Handle(msg *cevent.PbEventMessagee) error {
}
```


```Go
// Consume PayWx
// 支付公众号消息通知
type PayWx struct {
   handler.Base
}


func (h PayWx) Handle(msg *cevent.PbEventMessage) error {
}
```

2、只消费自己关注的 Type 类型消息

```Go
// Consume PaySms
type PaySms struct {
   handler.Base
}


func (h PaySms) Handle(msg *cevent.PbEventMessage) error {
   var (
       event = new(StatusEvent)
   )
   
   // 只消费自己关注的 Type 类型消息
   if !msg.Unmarshal(event, msg) {
       return nil
   }


   // 处理逻辑
}


// 事件数据消息
type PbEventMessage struct {
   // 事件数据类型：包/结构体名
   Type string
   // 事件数据
   Data []byte
}

func (msg PbEventMessage) Unmarshal(event PbEvent) error {
   // 事件数据类型校验
   t := utils.FullTypeNameOf(event)
   if msg.Type != t {
      return errors.Errorf("type %s cannot be converted to %s", msg.Type, t)
   }

   // 数据解码
   err := event.XXX_Unmarshal(msg.Data)
   if nil != err {
      return err
   }

   return nil
}
```

3、消费异常重试机制

消息消费采用 [至少一次]() 的消费语义，即 先消费后保存读取偏移量。若消费失败，则不更新读取偏移量，会继续消费该失败消息。

```Go
// 实现 ConsumerGroupHandler 接口
type defaultConsumer struct {
   handler cevent.Handler
}


func (c *defaultConsumer) Setup(sarama.ConsumerGroupSession) error {
   return nil
}

func (c *defaultConsumer) Cleanup(sarama.ConsumerGroupSession) error {
   return nil
}

// ConsumeClaim must start a consumer loop of ConsumerGroupClaim's Messages().
func (c *defaultConsumer) ConsumeClaim(session sarama.ConsumerGroupSession, claim sarama.ConsumerGroupClaim) error {
   for msg := range claim.Messages() {
      c.logger.Debugf(
         "message topic[%q] timestamp[%v] partition[%d] offset[%d]",
         msg.Topic, msg.Timestamp, msg.Partition, msg.Offset,
      )

      // 解析消息
      pbMsg := &cevent.PbEventMessage{}
      err := json.Unmarshal(msg.Value, pbMsg)
      if nil != err {
           return errors.Wrapf(err, "msg unmarshal failed")
      }

      // 消费逻辑，失败返回错误
      if err := c.handler(pbMsg); err != nil {
           c.logger.Info(fmt.Sprintf("event handle failed, data: %s, err: %s", msg.Value, err))
           return errors.Wrapf(err, "event handle failed，data: %s", msg.Value)
      }
	  


      // 成功，更新偏移量标记该消息已被消费过
      session.MarkMessage(msg, "")
   }

   return nil
}
```

由于 [至少一次]() 消费语义，会导致消息重复消费，因此消费逻辑需要做幂等处理。


4、不同业务逻辑的 Consume 应该使用不同的 Group

一是，为了减少不同业务逻辑失败时之间的相互影响；二是，同一个消息在同一个 Group 的 Consume，只会被消费一次，否则存在部分 Consume 丢失消息的情况。

```Go
  consume.Listen("order-pay-sms", message.PaySms{}.Handle)
  consume.Listen("order-pay-wx", message.PayWx{}.Handle)
```

## 容错处理

为了保持最终数据一致性，消息在生产和消费时都做了重试机制。

### Producer

1、推送失败重试机制

投递消息使用同步应答模式，当消息推送失败时，这里才用 [最大努力尝试]() 策略保持数据最终一致性。

![推送失败重试机制](//www.fanhaobai.com/2020/05/use-kafka/1589251986346.png)

### Consumer

2、消费异常重试机制

![消费异常重试机制](//www.fanhaobai.com/2020/05/use-kafka/1589258896838.jpg)

> 特别注意需要处理脏数据，防止因为错误数据导致消费阻塞。

3、只消费自己关注的 Type 类型消息

![关注只关注Type类型消息](//www.fanhaobai.com/2020/05/use-kafka/1589258912991.jpg)

具体实现，见 [业务消费](#业务消费) 部分。

## 总结

在分布式系统中引入消息系统，使得各系统可以只关注自己的业务逻辑，系统维护性更强，同时能极大的提高系统的稳定性。但是由于具有异步特性，存在一定的使用场景限制，对于实时响应的系统，还是建议直接使用 RPC 调用完成交互。