---
title: 如何实现一个自定义规则引擎
date: 2024-04-20 17:00:00
tags:
- 架构
---

规则引擎的功能可以简化为当满足一些条件时触发一些操作，通常使用 DSL 自定义语法来表述。规则引擎需要先解析 DSL 语法形成语法树，然后遍历语法树得到完整的语法表达式，最后执行这些语法表达式完成规则的执行。

![规则引擎](//www.fanhaobai.com/2024/04/design-rule-engine/12805423-37FB-4225-91E3-EC6473BA720C.png)<!--more-->

本文以 [gengine](https://github.com/bilibili/gengine) 为例来探讨如果设计和实现一个自定义规则引擎。

## 支持的语义

为了满足常见的业务规则，规则引擎应该要支持的语义有：

### 逻辑与算术运算

* 数学运算（+、-、*、/）
* 逻辑运算（&&、||、!）
* 比较运算（==、!=、>、<、>=、<=）

### 流程控制

* 条件（IF ELSE）
* 循环 (FOR)

### 高级语义

* 对象属性访问（对象.属性）
* 方法调用（func()）

## 规则语法的解析

规则的 DSL 语法定义应该简单明了，gengine 使用了开源的语法解析器 Antlr4 来定义和解析规则语法。

### 定义规则语法

一个规则的 DSL 基本语法格式如下：

```golang
rule "rulename" "rule-describtion" salience  10
begin

//规则体

end
```

其中规则体为具体规则语义，由上述的 [逻辑与算术运算](#支持的语义)、[流程控制](#支持的语义)、[高级语义](#支持的语义) 组合而成。 

例如，**判断为一个大额异常订单**的规则体：

```golang
if Order.Price>= 1000000 {
    return
}
```

### 编写解析器语法

Antlr4 解析器语法定义文件后缀名为`.g4`，以下内容为解析器的语法定义，解析器根据语法定义去逐行解析生成语法树。

这里省略了一些非核心的语法定义并做了简化，完整内容查看 [gengine.g4](//www.fanhaobai.com/2024/04/design-rule-engine/gengine.g4)]

```golang
grammar gengine;

primary: ruleEntity+;
// 规则定义
ruleEntity:  RULE ruleName ruleDescription? salience? BEGIN ruleContent END;
ruleName : stringLiteral;
ruleDescription : stringLiteral;
salience : SALIENCE integer;
// 规则体
ruleContent : statements;
statements: statement* returnStmt?;

// 基本语句
statement : ifStmt | breakStmt;

expression : mathExpression
            | expression comparisonOperator expression
            | expression logicalOperator expression
            ;

mathExpression : mathExpression  mathMdOperator mathExpression
               | mathExpression  mathPmOperator mathExpression
               | expressionAtom
               | LR_BRACKET mathExpression RR_BRACKET
               ;

expressionAtom
    : functionCall
    | constant
    | variable
    ;
returnStmt : RETURN expression?;
ifStmt : IF expression LR_BRACE statements RR_BRACE elseIfStmt*  elseStmt?;
elseStmt : ELSE LR_BRACE statements RR_BRACE;

constant
    : booleanLiteral
    | integer
    | stringLiteral
    ;
functionArgs
    : (constant | variable  | functionCall | expression)  (','(constant | variable | functionCall | expression))*
    ;
integer : MINUS? INT;
stringLiteral: DQUOTA_STRING;
booleanLiteral : TRUE | FALSE;
functionCall : SIMPLENAME LR_BRACKET functionArgs? RR_BRACKET;
variable :  SIMPLENAME | DOTTEDNAME;
mathPmOperator : PLUS | MINUS;
mathMdOperator : MUL | DIV;
comparisonOperator : GT | LT | GTE | LTE | EQUALS | NOTEQUALS;

// 关键字省略
```

### 解析器生成语法树

如，**判断为一个大额异常订单**的规则：

```
rule "order-large-price" "订单大额金额" salience 10
begin
    if Order.Price >= 1000000 {
        return
    }
end
```

语法解析器解析之后，生成语法树：

![语法树](//www.fanhaobai.com/2024/04/design-rule-engine/6082eaf6-9534-4989-86d6-2422a3ab54b0.png)

### 遍历语法树生成语句表达式

解析器生成语法树之后，只需要遍历语法树即可得到规则完整的语句表达式。 Antlr4 解析器会生成 Listener 接口，这些接口在遍历语法树时会被调用。

```golang
type gengineListener interface {
	antlr.ParseTreeListener
	// 省略了一些只列举了部分方法
	// EnterRuleEntity is called when entering the ruleEntity production.
	EnterRuleEntity(c *RuleEntityContext)
    // ExitRuleEntity is called when exiting the ruleEntity production.
    ExitRuleEntity(c *RuleEntityContext)
	// EnterRuleContent is called when entering the ruleContent production.
	EnterRuleContent(c *RuleContentContext)
    // ExitRuleContent is called when exiting the ruleContent production.
    ExitRuleContent(c *RuleContentContext)
	// EnterStatement is called when entering the statement production.
	EnterStatement(c *StatementContext)
    // ExitStatement is called when exiting the statement production.
    ExitStatement(c *StatementContext)
    // EnterIfStmt is called when entering the ifStmt production.
    EnterIfStmt(c *IfStmtContext)
    // ExitIfStmt is called when exiting the ifStmt production.
    ExitIfStmt(c *IfStmtContext)
	// EnterExpression is called when entering the expression production.
	EnterExpression(c *ExpressionContext)
    // ExitExpression is called when exiting the expression production.
    ExitExpression(c *ExpressionContext)
	// EnterInteger is called when entering the integer production.
	EnterInteger(c *IntegerContext)
    // ExitInteger is called when exiting the integer production.
    ExitInteger(c *IntegerContext)
}
```

可以发现在遍历语法树时，每个节点都有 EnterXXX() 和 ExitXXX() 方法存在，是成对出现的。

因此要遍历语法树只需要实现 gengineListener 接口即可，gengine 巧妙的引入`栈`结构，遍历完语法树后（树的递归遍历就是进栈出栈过程），就得到了完整的规则语句表达式。 这里只列举部分方法，完整实现见 [gengine_parser_listener](https://github.com/bilibili/gengine/blob/main/internal/iparser/gengine_parser_listener.go)。

```golang
type GengineParserListener struct {
	parser.BasegengineListener

	KnowledgeContext *base.KnowledgeContext
	Stack            *stack.Stack
}

func (g *GengineParserListener) EnterRuleEntity(ctx *parser.RuleEntityContext) {
    if len(g.ParseErrors) > 0 {
        return
    }
    entity := &base.RuleEntity{
        Salience: 0,
    }
    g.ruleName = ""
    g.ruleDescription = ""
    g.salience = 0
    g.Stack.Push(entity)
}

func (g *GengineParserListener) ExitRuleEntity(ctx *parser.RuleEntityContext) {
    if len(g.ParseErrors) > 0 {
        return
    }
    entity := g.Stack.Pop().(*base.RuleEntity)
    g.KnowledgeContext.RuleEntities[entity.RuleName] = entity
}
```

gengine 通过解析器解析规则内容之后，规则的数据结构如下：

![规则数据结构](//www.fanhaobai.com/2024/04/design-rule-engine/65ebb70a-3e2d-4e20-a1f2-227fc08c0669.png)

全局的 hashmap 以规则名为 key，规则体为 value，规则体中的 ruleContent 为该规则所有的语句表达式列表，列表中的值指向具体的语句表达式实体，

语句表达式实体由**逻辑与算术运算**、**流程控制（IF、FOR）**等基本语句组成。

## 规则语法的执行

其实遍历语法树的过程中，将规则的执行逻辑也放入 ExitXXX() 方法，这样就能完成规则的解析和执行。但是 gengine 没有这么做，而是将规则的解析和执行解耦，
因为规则的解析往往只需要初始化一次，或者在规则有变更时热更新解析规则，而规则的执行则是在需要校验规则的时候。

从 gengine 的规则数据结构可知，只需要遍历全局的 hashmap，即可按顺序执行所有的规则（顺序模式），执行每一个规则后会通过`addResult()`方法记录执行结果：

```golang
// 顺序模式
func (g *Gengine) Execute(rb *builder.RuleBuilder, b bool) error {
	for _, r := range rb.Kc.RuleEntities {
		v, err, bx := r.Execute(rb.Dc)
		if bx {
			// 记录每个规则执行结果
			g.addResult(r.RuleName, v)
		}
	}
    // 省略部分
	...
}
```

对于某一个规则的执行，则会去遍历规则体 ruleContent 的所有语句表达式列表，然后按顺序去执行该规则下的所有语句表达式：

```golang
func (s *Statements) Evaluate(dc *context.DataContext, Vars map[string]reflect.Value) (reflect.Value, error, bool) {
	for _, statement := range s.StatementList {
		v, err, b := statement.Evaluate(dc, Vars)
		if err != nil {
			return reflect.ValueOf(nil), err, false
		}

		if b {
			// return的情况不需要继续执行
			return v, nil, b
		}
	}
	if s.ReturnStatement != nil {
		return s.ReturnStatement.Evaluate(dc, Vars)
	}
	return reflect.ValueOf(nil), nil, false
}
```

gengine 为每个语句类型都实现了 Evaluate() 方法，这里只讨论 IF 语句的执行：

```golang
type IfStmt struct {
	Expression     *Expression
	StatementList  *Statements
	ElseIfStmtList []*ElseIfStmt
	ElseStmt       *ElseStmt
}

func (i *IfStmt) Evaluate(dc *context.DataContext, Vars map[string]reflect.Value) (reflect.Value, error, bool) {
	// 执行条件表达式
	it, err := i.Expression.Evaluate(dc, Vars)
	if err != nil {
		return reflect.ValueOf(nil), err, false
	}
    // 执行条件为真时的语句
	if it.Bool() {
		if i.StatementList == nil {
			return reflect.ValueOf(nil), nil, false
		} else {
			return i.StatementList.Evaluate(dc, Vars)
		}
	}

    return reflect.ValueOf(nil), nil, false
}
```

其中条件表达式`Expression.Evaluate()`为计算条件表达式的值：

```golang
func (e *Expression) Evaluate(dc *context.DataContext, Vars map[string]reflect.Value) (reflect.Value, error) {
	// 原子表达式
	var atom reflect.Value
	if e.ExpressionAtom != nil {
		evl, err := e.ExpressionAtom.Evaluate(dc, Vars)
		if err != nil {
			return reflect.ValueOf(nil), err
		}
		atom = evl
	}
	
	// 比较操作
	if e.ComparisonOperator != "" {
		// 计算左值
		lv, err := e.ExpressionLeft.Evaluate(dc, Vars)
		if err != nil {
			return reflect.ValueOf(nil), err
		}
		// 计算右值
		rv, err := e.ExpressionRight.Evaluate(dc, Vars)
		if err != nil {
			return reflect.ValueOf(nil), err
		}
        // 省略了类型转化
        switch e.ComparisonOperator {
        case "==":
			b = reflect.ValueOf(lv == rv)
            break
        case "!=":
            b = reflect.ValueOf(lv != rv)
            break
        case ">":
            b = reflect.ValueOf(lv > rv)
            break
        case "<":
            b = reflect.ValueOf(lv < rv)
            break
        case ">=":
            b = reflect.ValueOf(lv >= rv)
            break
        case "<=":
            b = reflect.ValueOf(lv <= rv)
            break
        }
	}
}
```

递归执行到`ExpressionAtom.Evaluate()`原子表达式时，则可以得到该原子表达式的值以结束递归：

```golang
func (e *ExpressionAtom) Evaluate(dc *context.DataContext, Vars map[string]reflect.Value) (reflect.Value, error) {
	if len(e.Variable) > 0 {
		// 是变量则取变量值，通过反射获取注入的自定义对象值
		return dc.GetValue(Vars, e.Variable)
	} else if e.Constant != nil {
		// 是常量就返回值
		return e.Constant.Evaluate(dc, Vars)
	}
	// 省略部分
}
```

## 支持自定义对象注入

在上下文中注入自定义对象后，就可以在规则中使用注入的对象。使用例子：

```golang
// 规则体
rule "test-object" "测试自定义对象" salience 10
begin
    // 访问自定义对象Order
    if Order.Price >= 1000000 {
        return
    }
end

// 注入自定义对象Order
dataContext := gctx.NewDataContext()
dataContext.Add("Order", Order)
```

现在来看下 gengine 的具体实现，主要是使用反射特性：

```golang
func (dc *DataContext) Add(key string, obj interface{}) {
	dc.lockBase.Lock()
	defer dc.lockBase.Unlock()
	dc.base[key] = reflect.ValueOf(obj)
}
```

gengine 解析规则时会将自定义对象标记为`variable`类型，通过 GetValue() 获取自定义对象属性值：

```golang
// 获取变量值
func (dc *DataContext) GetValue(Vars map[string]reflect.Value, variable string) (reflect.Value, error) {
	if strings.Contains(variable, ".") {
        // 对象a.b
		structAndField := strings.Split(variable, ".")
		if len(structAndField) == 2 {
			a := structAndField[0]
			b := structAndField[1]
			// 获取注入的对象
			dc.lockBase.Lock()
			v, ok := dc.base[a]
			dc.lockBase.Unlock()
			if ok {
				return core.GetStructAttributeValue(v, b)
			}
		}
	}
}

// 反射获取对象属性值
func GetStructAttributeValue(obj reflect.Value, fieldName string) (reflect.Value, error) {
    stru := obj
    var attrVal reflect.Value
    if stru.Kind() == reflect.Ptr {
        attrVal = stru.Elem().FieldByName(fieldName)
    } else {
        attrVal = stru.FieldByName(fieldName)
    }
    return attrVal, nil
}
```

## 支持自定义方法注入

同样在上下文中注入自定义方法后，就可以在规则中使用注入的方法。使用例子：

```golang
// 规则体
rule "test-func" "测试自定义方法" salience 10
begin
    // 自定义方法GetCount获取指标数据（患者当天的订单数量）
    num = GetCount("order-patient-id", Order.PatientId)
	if num >= 5 {
        return
    }
end

// 注入自定义方法GetData
dataSvc := s.indicatorDao.NewDataService(ctx)
dataContext := gctx.NewDataContext()
dataContext.Add("GetCount", dataSvc.GetCount)
```

gengine 自定义方法的注入也是使用反射来实现，自定义方法的注入同自定义对象一样也是使用 Add() 方法注入。

gengine 解析规则时会将自定义方法标记为`functionCall`类型：

```golang
func (dc *DataContext) ExecFunc(Vars map[string]reflect.Value, funcName string, parameters []reflect.Value) (reflect.Value, error) {
    // 获取注入的方法
    dc.lockBase.Lock()
    v, ok := dc.base[funcName]
    dc.lockBase.Unlock()
    if ok {
        args := core.ParamsTypeChange(v, parameters)
		// 调用方法
        res := v.Call(args)
        raw, e := core.GetRawTypeValue(res)
        if e != nil {
            return reflect.ValueOf(nil), e
        }
        return raw, nil
    }
}
```

## 支持并发执行

通常情况下顺序模式执行即可满足要求，但是当规则量比较大时，顺序执行的耗时就会比较长。

![顺序模式](//www.fanhaobai.com/2024/04/design-rule-engine/36E0B373-95A2-4E26-AFE2-ED9522CCB708.png)

规则引擎在执行所有规则的时候，其实是遍历全局的 hashmap 然后再顺序执行每一个规则，且每个规则之间没有依赖关系，因此可以每一个规则一个协程来并发执行。

```golang
func (g *Gengine) ExecuteConcurrent(rb *builder.RuleBuilder) error {
	var wg sync.WaitGroup
	wg.Add(len(rb.Kc.RuleEntities))
	for _, r := range rb.Kc.RuleEntities {
		rr := r
		// 协程并发
		go func() {
			v, e, bx := rr.Execute(rb.Dc)
			if bx {
				g.addResult(rr.RuleName, v)
			}
			wg.Done()
		}()
	}
	wg.Wait()
	// 省略部分
}
```

## 使用场景

有了规则引擎之后，很多在业务代码中的 if-else、switch 硬编码，都能抽象为规则并使用规则引擎，这样能极大地缩短需求开发周期。

### 业务风控

通过业务数据分析，可以抽象出用户异常行为的规则：

![风控规则](//www.fanhaobai.com/2022/12/rule-engine/C0C5B489-90D1-4937-A8D8-55459E951ABC.png)

然后，风控系统在判断是否为风险操作时，只需要规则引擎加载并执行风控规则，即可得到结果。
想要提高风控系统的准确性，只需要不断地迭代完善风控规则。

![风控系统](//www.fanhaobai.com/2022/12/rule-engine/C290970F-D33E-49DF-846B-577E62694709.png)

规则引擎在业务风控的实践，可以参考 [基于准实时规则引擎的业务风控实践](https://www.fanhaobai.com/2022/06/risk-rule.html)。

### 运营活动

拿最常见的抽奖和做任务 2 种运营活动来说，都可以将具体活动逻辑抽象为业务规则：
① 抽奖，不同的人&不同的场景对应不同的奖池（中奖概率与奖品集合规则）；
② 做任务，任务领取规则、任务完成指标动态可配（任务规则）；

![运营活动](//www.fanhaobai.com/2022/12/rule-engine/30B59826-F443-4D9A-AC98-42F7E28127D5.png)

### 内容分发

针对某些特定的用户或者某种场景的用户，下发特定的展示内容或者推送短信等触达消息，都可以将这些特定用户的逻辑梳理为内容分发规则。

![内容分发](//www.fanhaobai.com/2022/12/rule-engine/E937E855-8B7C-4B4C-9761-0764D563BE42.png)