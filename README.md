# Judy

Julia debugger for vscode (beta)

**Currently we have on plan for continuing this project**

## Getting Started

Judy are implemented in Julia. Judy now can only run with [judy-vscode](https://github.com/judy-vscode/Adapter). Although Judy can already run on Linux, it currently only be used in Windows.

Below are the prerequisites to enable Judy running as the back-end for judy-vscode.

### Prerequisites

* For Windows users, command `$julia` must be enabled with powershell or prompt. To enable this:

  ```
  Find Julia installation position and add its path into environment variable PATH. 
  (Default Julia installation path should be at: C:\Users\xxx\AppData\Local\Julia-1.x.x\bin)
  ```

* Julia version should be 1.0.x. 

* Julia should be able to port 'JSON' pacakge. To test it, enable Julia REPL and type `import JSON`. If it fails to import, follow the instructions presented by Julia REPL to install this package.

### Installing

* No need for installing. 

* To make sure whether Judy can work, under `Judy/` run (in powershell)
  
  ```
  $julia judy.jl
  ``` 

  If you see the program gets stuck without any errors, it should be good.

## Features

Judy now is still in Beta, we will list what Judy can and what Judy can't.

For better understanding Judy's feature, word `block` will be used under this definition: A block consists of multiple source code lines and is the minimal set of codes which can be successfully executed by Julia. For example:

``` julia
if 5 > 3
  println(5)
else
  println(3)
end
```

is a block while:

``` julia
if 5 > 3
  println(5)
```
and
``` julia
if 5 > 3
```
and
``` julia
a = 3
```
are not blocks. Because the first can't be executed by Julia (lack of end) and the second and third only have one line (where block requires multiple lines).

### What Judy can

* Support Main Module `step over` and `continue`. 

* Support multiple source files debugging (with `include` call in Julia)

* Support watching variables and unrolling them on Main Global level.

* Support setting breakpoints even the debuggee is running. (Setting new breakpoints inside blocks should make sure this block has not been passed or is on running)

### What Judy can't

* Local varaibles, such as variables inside function definitions, can't be watched since Julia didn't offer a runtime API to get these information.

* Stacktrace is not accurate since it will include some Judy runtime stacktrace.

* `step in` is not supported. (But you can set a breakpoint inside function definitions and use `continue` to step into functions)

* Only `continue` can be executed inside blocks (If you click `step over`, it will run as `continue`)

* Currently we only support top-module (a.k.a. Main Module) debugging, which means if Judy is debugging inside your own module, it will only treat your module as a big block (so you may only use continue.), and global variables inside this module will not be able to watch.

## Running the tests

All test files have been placed under `test/`. Script under each test file offers testing JSON message for Judy.

### Before Test

It can be tested on both Linux and Windows.

For Windows user, you need have [netcat](https://eternallybored.org/misc/netcat/) tools since our implementation is based on JSON RPC.

JSON messeage consists of:

  * Head: A number in textual eight digit to indicate length of message Body

  * Body: JSON body message including result, path, calling function names.

### Test Steps

* Create three terminals / powershells sessions: We use t1, t2, t3 to denote them.
  
* Do following steps in sequence:
  * t1: `nc -l 127.0.0.1 18001`
  * t2: `julia judy.jl`
  * t3: `nc 127.0.0.1 8000`
  
* Whenever it needs input with file path (such as breakpoints, launch method), you should change JSON body's content to your file location (absolute path) and update corresponding JSON head

* Copy the script line into t3, but don't enter `\n` in t3 since JSON RPC is not allowed `\n` for communication. (If you type `\n` you need to copy the next JSON message without the first character `0`)

* Type `\n` to oberserve the output in t1 and t2

## Contributing

All kinds of contributions are welcomed!

When contributing to this repository, please first discuss the change you wish to make via issue, email, or any other method with the owners of this repository before making a change.

## Authors

* Zhiqi Lin (ralzq01@outlook.com)

* Yu Xing (xyyimian@mail.ustc.edu.cn)

## License

This project is under MIT license.
