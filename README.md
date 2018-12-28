# Judy

Julia debugger for vscode (beta)

## Getting Started

Judy are implemented in Julia. Judy now can only run with [judy-vscode](https://github.com/judy-vscode/Adapter). Although Judy can already run on Linux, judy-vscode now only provides supports with Windows.

Below are the prerequisites to enable Judy running as the back-end for judy-vscode.

### Prerequisites

* For Windows users, command `$julia` must be enabled with powershell or prompt. To enable this:

  ```
  Find Julia installation position and add its path into environment variable PATH. 
  (Default Julia installation path should be at: C:\Users\xxx\AppData\Local\Julia-1.x.x\bin)
  ```

* We support Julia version with 1.0.x. 

* Julia should enable porting 'JSON' pacakge. To test it, enable Julia REPL and type `import JSON`. If it fails to import, follow the instruction presented by Julia REPL to install this package.

### Installing

* No need for installing. 

* To make sure whether Judy can work, under `Judy/` and run (in powershell)
  
  ```
  $julia judy.jl
  ``` 

  If you see the program gets stuck without any errors, it should be good.

## Features

Judy now is still in Beta, we will list what Judy can and what Judy can't.

Word `block` will be used under this definition: If Julia can't run 

### What Judy can

* Support Main Module `step over` and `continue`. 

* Support multiple source files debugging (with `include` call in Julia)

* Support watching variables and unrolling them on Main Global level.

* Support setting breakpoints even the debuggee is running. (Setting new breakpoints inside blocks should make sure this block haven't been passed or on running)

### What Judy can't

* Local varaibles, such as variables inside function definitions, can't be watched since Julia didn't offer a runtime API to get these information.

* Stacktrace is not accurate since it will include some Judy runtime stacktrace.

* `step in` is not supported. (But you can set a breakpoint inside function definitions and use `continue` to step into functions)

* Only `continue` can be enabled inside blocks (If you click `step over`, it will run as `continue`)

* Currently we only support top-module (Main Module) debugging, which means if Judy is debuging inside your own module, it will only treat your module as a big block (so you may only be able to use continue.), and global variables inside this module will not be able to watch.

## Running the tests

All test files have been placed under `test/`. Script has been offered for testing Judy.

### Before Test

It can be tested on Linux and Windows.

For Windows user, you need have [netcat](https://eternallybored.org/misc/netcat/) tools since our implementation is based on JSON RPC.

JSON messeage consists of:

  * Head: A number of eight digit in text to indicate how many characters with Body

  * Body: JSON body message including result, function definition.

### Test Steps

* Create three terminals / powershells: We use t1, t2, t3 to denote them.
  
* Do following things under this order:
  * t1: `nc -l 127.0.0.1 18001`
  * t2: `julia judy.jl`
  * t3: `nc 127.0.0.1 8000`
  
* Whenever it needs input with filepath (such as breakpoints, launch method), change Json body to your file location (absolute path) and update corresponding JSON head

* Copy the script line into t3, and don't enter `\n` in t3 since JSON RPC is not allowed `\n` for communication. (If you type `\n` you need to copy the next JSON message leaving the first character `0`)

* Type `\n` to oberserve the output in t1 and t2

## Contributing

We are really welcome for all kinds of contributions!

When contributing to this repository, please first discuss the change you wish to make via issue, email, or any other method with the owners of this repository before making a change.

## Authors

* Zhiqi Lin (ralzq01@outlook.com)

* Yu Xing
