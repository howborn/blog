---
title: 异步、并发、协程原理
date: 2017-11-13 10:45:30
tags:
- 系统原理
categories:
- 系统原理
---

> 原文：http://wiki.phpboy.net/doku.php?id=2017-07:55-异步_并发_协程原理.md

Linux 操作系统在设计上将虚拟空间划分为用户空间和内核空间，两者做了隔离是相互独立的，用户空间给应用程序使用，内核空间给内核使用。
![](https://img3.fanhaobai.com/2017/11/synchronised-asynchronized-coroutine/a89c6e5b-facd-47a1-a26b-c8fb747e9650.jpg)<!--more-->

## 一、异步

## 应用程序和内核

内核具有最高权限，可以访问受保护的内存空间，可以访问底层的硬件设备。而这些是应用程序所不具备的，但应用程序可以通过调用内核提供的接口来间接访问或操作。所谓的常见的 IO 模型就是基于应用程序和内核之间的交互所提出来的。以一次网络 IO 请求过程中的 read 操作为例，请求数据会先拷贝到系统内核的缓冲区（内核空间），再从操作系统的内核缓冲区拷贝到应用程序的地址空间（用户空间）。而从内核空间将数据拷贝到用户空间过程中，就会经历两个阶段： 

* 等待数据准备
* 拷贝数据

也正因为有了这两个阶段，才提出了各种网络 I/O 模型。

### Unix/Linux的体系架构

![](https://img4.fanhaobai.com/2017/11/synchronised-asynchronized-coroutine/88bb24ee-b443-407d-ad14-fdae5a7113d6.png)

### 同步和异步

同步（Synchronised）和异步（Asynchronized）的概念描述的是应用程序与内核的交互方式，同步是指应用程序发起 I/O 请求后需要等待或者轮询内核 I/O 操作完成后才能继续执行；而异步是指应用程序发起 I/O 请求后仍继续执行，当内核 I/O 操作完成后会通知应用程序，或者调用应用程序注册的回调函数。

### 阻塞和非阻塞

阻塞和非阻塞的概念描述的是应用程序调用内核 IO 操作的方式，阻塞是指 I/O 操作需要彻底完成后才返回到用户空间；而非阻塞是指 I/O 操作被调用后立即返回给用户一个状态值，无需等到 I/O 操作彻底完成。

**常见的网络I/O模型大概有四种：**

1. 同步阻塞IO（Blocking IO）
2. 同步非阻塞IO（Non-blocking IO）
3. IO多路复用（IO Multiplexing）
4. 异步IO（Asynchronous IO）

### IO多路复用

多路 I/O 复用模型是利用 select、poll、epoll 可以同时监察多个流的 I/O 事件的能力，在空闲的时候，会把当前线程阻塞掉，当有一个或多个流有 I/O 事件时，就从阻塞态中唤醒，于是程序就会轮询一遍所有的流（epoll 是只轮询那些真正发出了事件的流），并且只依次顺序的处理就绪的流，这种做法就避免了大量的无用操作。这里“多路”指的是多个网络连接，“复用”指的是复用同一个线程。采用多路 I/O 复用技术可以让单个线程高效的处理多个连接请求（尽量减少网络 IO 的时间消耗）。** IO 多路复用是异步阻塞的。**

## 二、并发

并发，在操作系统中，是指 **一个时间段** 中有几个程序都处于已启动运行到运行完毕之间，且这几个程序都是在同一个处理机上运行，但任一个时刻点上只有一个程序在处理机上运行。

**并发和并行的区别：**

* 并发（concurrency）：逻辑上具备同时处理多个任务的能力。
* 并行（parallesim）：物理上在同一时刻执行多个并发任务，依赖多核处理器等物理设备。

多线程或多进程是并行的基本条件，但单线程也可用协程做到并发。通常情况下，用多进程来实现分布式和负载平衡，减轻单进程垃圾回收压力；用多线程抢夺更多的处理器资源；用协程来提高处理器时间片利用率。现代系统中，多核 CPU 可以同时运行多个不同的进程或者线程。所以并发程序可以是并行的，也可以不是。

## 三、协程

在了解协程前先了解一些概念：

### 1、线程模型

在现代计算机结构中，先后提出过两种线程模型：用户级线程（user-level threads）和内核级线程（kernel-level threads）。所谓用户级线程是指，应用程序在操作系统提供的单个控制流的基础上，通过在某些控制点（比如系统调用）上分离出一些虚拟的控制流，从而模拟多个控制流的行为。由于应用程序对指令流的控制能力相对较弱，所以，用户级线程之间的切换往往受线程本身行为以及线程控制点选择的影响，线程是否能公平地获得处理器时间取决于这些线程的代码特征。而且，支持用户级线程的应用程序代码很难做到跨平台移植，以及对于多线程模型的透明。用户级线程模型的优势是线程切换效率高，因为它不涉及系统内核模式和用户模式之间的切换；另一个好处是应用程序可以采用适合自己特点的线程选择算法，可以根据应用程序的逻辑来定义线程的优先级，当线程数量很大时，这一优势尤为明显。但是，这同样会增加应用程序代码的复杂性。有一些软件包（如 POSIXThreads 或 Pthreads 库）可以减轻程序员的负担。

内核级线程往往指操作系统提供的线程语义，由于操作系统对指令流有完全的控制能力，甚至可以通过硬件中断来强迫一个进程或线程暂停执行，以便把处理器时间移交给其他的进程或线程，所以，内核级线程有可能应用各种算法来分配处理器时间。线程可以有优先级，高优先级的线程被优先执行，它们可以抢占正在执行的低优先级线程。在支持线程语义的操作系统中，处理器的时间通常是按线程而非进程来分配，因此，系统有必要维护一个全局的线程表，在线程表中记录每个线程的寄存器、状态以及其他一些信息。然后，系统在适当的时候挂起一个正在执行的线程，选择一个新的线程在当前处理器上继续执行。这里“适当的时候”可以有多种可能，比如：当一个线程执行某些系统调用时，例如像 sleep 这样的放弃执行权的系统函数，或者像 wait 或 select 这样的阻塞函数；硬中断（interrupt）或异常（exception）；线程终止时，等等。由于这些时间点的执行代码可能分布在操作系统的不同位置，所以，在现代操作系统中，线程调度（thread scheduling）往往比较复杂，其代码通常分布在内核模块的各处。

内核级线程的好处是，应用程序无须考虑是否要在适当的时候把控制权交给其他的线程，不必担心自己霸占处理器而导致其他线程得不到处理器时间。应用线程只要按照正常的指令流来实现自己的逻辑即可，内核会妥善地处理好线程之间共享处理器的资源分配问题。然而，这种对应用程序的便利也是有代价的，即，所有的线程切换都是在内核模式下完成的，因此，对于在用户模式下运行的线程来说，一个线程被切换出去，以及下次轮到它的时候再被切换进来，要涉及两次模式切换：从用户模式切换到内核模式，再从内核模式切换回用户模式。在 Intel 的处理器上，这种模式切换大致需要几百个甚至上千个处理器指令周期。但是，随着处理器的硬件速度不断加快，模式切换的开销相对于现代操作系统的线程调度周期（通常几十毫秒）的比例正在减小，所以，这部分开销是完全可以接受的。

除了线程切换的开销是一个考虑因素以外，线程的创建和删除也是一个重要的考虑指标。当线程的数量较多时，这部分开销是相当可观的。虽然线程的创建和删除比起进程要轻量得多，但是，在一个进程内建立起一个线程的执行环境，例如，分配线程本身的数据结构和它的调用栈，完成这些数据结构的初始化工作，以及完成与系统环境相关的一些初始化工作，这些负担是不可避免的。另外，当线程数量较多时，伴随而来的线程切换开销也必然随之增加。所以，当应用程序或系统进程需要的线程数量可能比较多时，通常可采用线程池技术作为一种优化措施，以降低创建和删除线程以及线程频繁切换而带来的开销。

在支持内核级线程的系统环境中，进程可以容纳多个线程，这导致了多线程程序设计（multithreaded programming）模型。由于多个线程在同一个进程环境中，它们共享了几乎所有的资源，所以，线程之间的通信要方便和高效得多，这往往是进程间通信（IPC，Inter-Process Communication）所无法比拟的，但是，这种便利性也很容易使线程之间因同步不正确而导致数据被破坏，而且，这种错误存在不确定性，因而相对来说难以发现和调试。

### 2、什么是协同式和抢占式？

许多协同式多任务操作系统，也可以看成协程运行系统。说到协同式多任务系统，一个常见的误区是认为协同式调度比抢占式调度“低级”，因为我们所熟悉的桌面操作系统，都是从协同式调度（如 Windows 3.2， Mac OS 9 等）过渡到抢占式多任务系统的。实际上，调度方式并无高下，完全取决于应用场景。抢占式系统允许操作系统剥夺进程执行权限，抢占控制流，因而天然适合服务器和图形操作系统，因为调度器可以优先保证对用户交互和网络事件的快速响应。当年 Windows 95 刚刚推出的时候，抢占式多任务就被作为一大买点大加宣传。协同式调度则等到进程时间片用完或系统调用时转移执行权限，因此适合实时或分时等等对运行时间有保障的系统。  

另外，抢占式系统依赖于 CPU 的硬件支持。 因为调度器需要“剥夺”进程的执行权，就意味着调度器需要运行在比普通进程高的权限上，否则任何“流氓（rogue）”进程都可以去剥夺其他进程了。只有 CPU 支持了执行权限后，抢占式调度才成为可能。x86 系统从 80386 处理器开始引入 Ring 机制支持执行权限，这也是为何 Windows 95 和 Linux 其实只能运行在 80386 之后的 x86 处理器上的原因。而协同式多任务适用于那些没有处理器权限支持的场景，这些场景包含资源受限的嵌入式系统和实时系统。在这些系统中，程序均以协程的方式运行。调度器负责控制流的让出和恢复。通过协程的模型，无需硬件支持，我们就可以在一个“简陋”的处理器上实现一个多任务的系统。我们见到的许多智能设备，如运动手环，基于硬件限制，都是采用协同调度的架构。

### 协程基本概念

“协程”（Coroutine）概念最早由 Melvin Conway 于 1958 年提出。协程可以理解为纯用户态的线程，其通过协作而不是抢占来进行切换。相对于进程或者线程，协程所有的操作都可以在用户态完成，创建和切换的消耗更低。总的来说，协程为协同任务提供了一种运行时抽象，这种抽象非常适合于协同多任务调度和数据流处理。在现代操作系统和编程语言中，因为用户态线程切换代价比内核态线程小，协程成为了一种轻量级的多任务模型。

从编程角度上看，协程的思想本质上就是控制流的主动让出（yield）和恢复（resume）机制，迭代器常被用来实现协程，所以大部分的语言实现的协程中都有 yield 关键字，比如 Python、PHP、Lua。但也有特殊比如 Go 就使用的是通道来通信。

有趣的是协程的历史其实要早于线程。

WIKI 的解释：

>Coroutines are computer program components that generalize subroutines for non-preemptive multitasking, by allowing multiple entry points for suspending and resuming execution at certain locations. Coroutines are well-suited for implementing more familiar program components such as **cooperative tasks, exceptions, event loop, iterators, infinite lists and pipes.**  

### 进程、线程、协程的特点及区别

#### 进程（process）

* 进程是资源分配的最小单位
* 进程间不共享内存，每个进程拥有自己独立的内存
* 进程间可以通过信号、信号量、共享内存、管道、队列等来通信
* 新开进程开销大，并且 CPU 切换进程成本也大
* 进程由操作系统调度
* 多进程方式比多线程更加稳定

#### 线程（thread）

* 线程是程序执行流的最小单位
* 线程是来自于进程的，一个进程下面可以开多个线程
* 每个线程都有自己一个栈，不共享栈，但多个线程能共享同一个属于进程的堆
* 线程因为是在同一个进程内的，可以共享内存
* 线程也是由操作系统调度，线程是 CPU 调度的最小单位
* 新开线程开销小于进程，CPU 在切换线程成本也小于进程
* 某个线程发生致命错误会导致整个进程崩溃
* 线程间读写变量存在锁的问题处理起来相对麻烦

#### 协程（coroutine）

* 对于操作系统来说只有进程和线程，协程的控制由应用程序显式调度，非抢占式的
* 协程的执行最终靠的还是线程，应用程序来调度协程选择合适的线程来获取执行权
* 切换非常快，成本低。一般占用栈大小远小于线程（协程 KB 级别，线程 MB 级别），所以可以开更多的协程
* 协程比线程更轻量级

** 不同模型下用户空间与内核空间的关系：**

![](https://img5.fanhaobai.com/2017/11/synchronised-asynchronized-coroutine/a89c6e5b-facd-47a1-a26b-c8fb747e9650.jpg)

注：协程可以理解为上图中的用户级线程模型。

#### 支持协程的语言

 *  Simula
 *  Modula-2
 *  C#
 *  Lua
 *  Go
 *  JavaScript(ECMA-262 6th Edition) 
 *  Python
 *  Ruby
 *  Erlang
 *  PHP（PHP5.5+）
 *  ...

##### C协程

C 标准库里的函数 setjmp 和 longjmp 可以用来实现一种协程。

##### Go协程

Go 语言是原生支持语言级并发的，这个并发的最小逻辑单元就是 goroutine。goroutine 就是 Go 语言提供的一种用户态线程，当然这种用户态线程是跑在内核级线程之上的。当我们创建了很多的 goroutine，并且它们都是跑在同一个内核线程之上的时候，就需要一个 **调度器**（scheduler）来维护这些 goroutine，确保所有的 goroutine 都使用 CPU，并且是尽可能公平的使用 CPU 资源。Go 的 scheduler 比较复杂，它实现了 M:N 的模式。M:N 模式指的是多个 goroutine 在多个内核线程上跑，[Go 的 scheduler 可参考>>](http://morsmachine.dk/go-scheduler)。goroutine 让 Go 低成本地具有了高并发运算能力。另外 Go 协程是通过通道（channel）来通信的。  

注意：goroutine 的实现并不完全是传统意义上的协程。在协程阻塞的时候（CPU 计算或者文件 IO 等），多个 goroutine 会变成多线程的方式执行。

```GO
func main() {
    for i := 0; i < 100; i++ {
        go func() { // 启动一个goroutine
            fmt.Println(i)
        }()
    }
}
```

##### Python协程

Python 协程基于 Generator。Python 实现的 grep 例子：

```Python
def grep(pattern):
    while True:
        line = (yield)
        if pattern in line:
             print(line)

search = grep('coroutine')
next(search) # 启动一个协程
search.send("send sha ne")               
```

#####  Lua协程

Lua 中的协同是一协作的多线程，每一个协同等同于一个线程，yield-resume 可以实现在线程中切换。然而与真正的多线程不同的是，协同是非抢占式的。当程序运行到 yield 的时候，使用协程将上下文环境记录住，然后将程序操作权归还到主函数，当主函数调用 resume 的时候，会重新唤起协程，读取 yield 记录的上下文。这样形成了程序语言级别的多协程操作。

```Lua
co = coroutine.create(  -- 创建coroutine
    function(i)
        print(i);
    end
)

coroutine.resume(co, 1)  -- 唤醒coroutine
print(coroutine.status(co))  -- 查看coroutine的状态

co = coroutine.wrap(
    function(i)
        print(i);
    end
)

co(1)

co2 = coroutine.create(
    function()
        for i=1,10 do
            print(i)
            if i == 3 then
                print(coroutine.status(co2)) 
                print(coroutine.running()) -- 返回正在跑的coroutine
            end
            coroutine.yield() -- 挂起coroutine
        end
    end
)
```

##### PHP协程

PHP 5.5 一个比较好的新功能是加入了对迭代生成器和协程的支持。PHP 协程也是基于 Generator，Generator 可以视为一种“可中断”的函数，而 yield 构成了一系列的“中断点”。PHP 协程没有 resume 关键字，而是“在使用的时候唤起”协程。

```PHP
function xrange($start, $end, $step = 1) {
    for ($i = $start; $i <= $end; $i += $step) {
        yield $i;
    }
}

foreach (xrange(1, 1000000) as $num) { // xrange返回的是一个Generator对象
    echo $num, "\n";
}
```

Swoole 在 2.0 开始内置协程（Coroutine）的能力，提供了具备协程能力 IO 接口（统一在命名空间Swoole\Coroutine\*）。基于 setjmp、longjmp 实现，在进行协程切换时会自动保存 Zend VM 的内存状态（主要是 EG 全局内存和 vm stack）。

由于 Swoole 是在底层封装了协程，所以对比传统的 PHP 层协程框架，开发者不需要使用 yield 关键词来标识一个协程 IO 操作，所以不再需要对 yield 的语义进行深入理解以及对每一级的调用都修改为 yield。

#### 适合使用协程的场景

1. 协程适合于 IO 密集型场景，这样能提高并发性，比如请求接口、Mysql、Redis 等的操作；
2. PHP 中利用协程还可以低成本处理处理大数据集合。[参考>>](http://www.laruence.com/2015/05/28/3038.html)；
3. 替代异步回调的代码风格；（协程令开发者可以无感知的用同步的代码编写方式达到异步 IO 的效果和性能，避免了传统异步回调所带来的离散的代码逻辑和陷入多层回调中导致代码无法维护。但相比普通的异步回调程序，协程写法会多增加额外的内存占用和一些 CPU 开销。 ）

## 四、协程与异步和并发的联系

[协程与异步](#)：协程并不是说替换异步，协程一样可以利用异步实现高并发。 

[协程与并发](#)：协程要利用多核优势就需要比如通过调度器来实现多协程在多线程上运行，这时也就具有了并行的特性。如果多协程运行在单线程或单进程上也就只能说具有并发特性。

## 五、引用
* [协程 - 廖雪峰的官方网站](http://www.liaoxuefeng.com/wiki/001374738125095c955c1e6d8bb493182103fac9270762a000/0013868328689835ecd883d910145dfa8227b539725e5ed000)
* [http://www.dabeaz.com/coroutines/Coroutines.pdf](http://www.dabeaz.com/coroutines/Coroutines.pdf)
* [http://blog.rainy.im/2016/04/07/python-thread-and-coroutine/](http://blog.rainy.im/2016/04/07/python-thread-and-coroutine/)
* [https://www.zhihu.com/question/30133749](https://www.zhihu.com/question/30133749) 
* [http://www.ibm.com/developerworks/cn/opensource/os-cn-python-yield/](http://www.ibm.com/developerworks/cn/opensource/os-cn-python-yield/)
* [https://gocn.io/question/2](https://gocn.io/question/2)
* [http://morsmachine.dk/go-scheduler](http://morsmachine.dk/go-scheduler)
* [https://book.douban.com/annotation/28878170/](https://book.douban.com/annotation/28878170/)
* [http://www.cnblogs.com/fanzhidongyzby/p/4098546.html](http://www.cnblogs.com/fanzhidongyzby/p/4098546.html)
* [http://blog.tingyun.com/web/article/detail/621](http://blog.tingyun.com/web/article/detail/621)
* [http://www.ruanyifeng.com/blog/2015/04/generator.html](http://www.ruanyifeng.com/blog/2015/04/generator.html)
* [http://callbackhell.com/](http://callbackhell.com/)
* [http://www.ruanyifeng.com/blog/2016/12/user_space_vs_kernel_space.html](http://www.ruanyifeng.com/blog/2016/12/user_space_vs_kernel_space.html)

<strong>相关文章 [»](#)</strong>

* [用PHP玩转进程之一 — 基础](https://www.fanhaobai.com/2018/08/process-php-basic-knowledge.html) <span>（2018-08-28）</span>
* [用PHP玩转进程之二 — 多进程PHPServer](https://www.fanhaobai.com/2018/09/process-php-multiprocess-server.html) <span>（2018-09-02）</span>
