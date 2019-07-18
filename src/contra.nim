## Contra
## ======
##
## Lightweight Contract Programming (DbC) and optional Hardened Build mode
## (Based from Debian Hardened & Gentoo Hardened),designed for ``proc``/``func``,
## 2 Templates for Preconditions (Require) & Postconditions (Ensure) on 9 LoC.
## For performance it wont generate any code when build for release. Recommended
## `func <https://nim-lang.org/docs/manual.html#procedures-func>`_ and use of
## `Concepts <https://nim-lang.org/docs/manual_experimental.html#concepts>`_
## - https://en.wikipedia.org/wiki/Defensive_programming#Other_techniques
## - http://stackoverflow.com/questions/787643/benefits-of-assertive-programming

template preconditions*(requires: varargs[bool]) =
  ## Require (Preconditions) for Contract Programming on proc/func.
  when not defined(release) or defined(contracts):
    for i, contractPrecondition in requires: assert(contractPrecondition,
        "\nContract Precondition (Require) failed assert on position: " & $i)

template postconditions*(ensures: varargs[bool]) =
  ## Ensure (Postconditions) for Contract Programming on proc/func.
  when not defined(release) or defined(contracts):
    defer:
      for i, contractPostcondition in ensures: assert(contractPostcondition,
          "\nContract Postcondition (Ensure) failed assert on position: " & $i)

template hardenedBuild*() =
  ## Optional Security Hardened mode (Based from Debian Hardened & Gentoo Hardened).
  ## See: http:wiki.debian.org/Hardening & http:wiki.gentoo.org/wiki/Hardened_Gentoo
  ## http:security.stackexchange.com/questions/24444/what-is-the-most-hardened-set-of-options-for-gcc-compiling-c-c
  # Hardened build is ideal companion for a Contracts module,still optional anyway.
  when defined(hardened) and defined(gcc) and not defined(objc) and not defined(js) and not defined(cpp):
    when defined(danger):
      {.fatal: "-d:hardened is incompatible with -d:danger".}
    when not defined(contracts):
      {.fatal: "-d:hardened requires -d:contracts".}
    {.hint: "Security Hardened mode is enabled.".}
    const hf = "-fstack-protector-all -Wstack-protector --param ssp-buffer-size=4 -pie -fPIE -Wformat -Wformat-security -D_FORTIFY_SOURCE=2 -Wall -Wextra -Wconversion -Wsign-conversion -mindirect-branch=thunk -mfunction-return=thunk -fstack-clash-protection -Wl,-z,relro,-z,now -Wl,-z,noexecstack -fsanitize=signed-integer-overflow -fsanitize-undefined-trap-on-error -Wl,-z,noexecheap -fno-common"
    {.passC: hf, passL: hf.}

  when defined(danger) and defined(gcc) and not defined(hardened) and not defined(objc) and not defined(js):
    {.passC: "-flto -ffast-math -march=native -mtune=native".}

  when defined(release):
    {.passL: "-s".}

  when defined(glibc) and defined(gcc) and defined(amd64) and defined(linux) and not defined(objc) and not defined(js) and not defined(cpp):
    {.hint: "Compatibility with GlibC >= 2.5 is enabled.".}
    import os
    const force_link_glibc_25 = currentSourcePath().splitPath.head / "force_link_glibc_25.h"
    {.passC: "-include " & force_link_glibc_25.}


# when isMainModule:
runnableExamples:
  hardenedBuild() ## Security Hardened mode enabled, compile with:  -d:hardened

  func funcWithContract(mustBePositive: int): int {.compiletime.} =
    preconditions mustBePositive > 0, mustBePositive > -1 ## Require (Preconditions)
    postconditions result > 0, result < int32.high        ## Ensure  (Postconditions)
    result = mustBePositive - 1 ## Mimic some logic, notice theres no "body" block
  assert funcWithContract(2) > 0

  func funcWithoutContract(mustBePositive: int): int =
    result = mustBePositive - 1 ## Same func but without Contract templates.
  echo funcWithoutContract(1) > 0, " <-- This must be 'true', if not is a Bug!"
