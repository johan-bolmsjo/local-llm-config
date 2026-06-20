# AGENTS.md — C Library Development Guidelines

## Project Overview

This is a C library built to the **C23 (ISO/IEC 9899:2024)** standard.
All tooling, code style, and architectural decisions are documented below.

- Take this complete file into considerations for any changes in the project.

- If the user's instructions conflict with any rule in this document, ask for explicit confirmation
  before overriding. Only then execute their instructions.

- Always ask before removing functionality or code that appears intentional.

## Language and Standard

| Setting         | Value                              |
|-----------------|------------------------------------|
| Standard        | **C23**                            |
| Extensions      | None — strict standard conformance |
| Encoding        | UTF-8 (NFC)                        |
| Line endings    | LF (`\n`)                          |

## Coding Conventions

### 1. Naming

As a general rule, use descriptive names with increased scope.
Short names are okay in small scopes, e.g. loop index variable name `i`.
Avoid needless uncommon abbreviations.

#### Naming of Functions

1. Functions that receives an "object" (defined below) as the first argument are named by the type
   of the object in PascalCase joined with an underscore (`_`) and the "method" operating on the
   object in camelCase. This style is commonly used in C for a limited form of object oriented
   programming.

```c
// GOOD: Function name prefixed with the receiving object's type name
void ObjectType_someMethod(ObjectType* receiverObject, int someArgument);

// GOOD: Function name prefixed with the receiving object's type name
uint64_t Hash_sum64(Hash* hash);

// BAD: The "method" part of the function name is in PascalCase
uint64_t Hash_Sum64(Hash* hash);
```

- **object definition**: An object is a user defined type operated on by "methods". The object is
  passed as the first argument to methods and is also called the "receiver" (`this` in C++).

2. Plain functions, functions that do not operate on an "object", have their name in (lower) camelCase.

```c
// GOOD: Plain function name in camelCase
int intCompare(int lhs, int rhs);

// BAD: Plain function name in snake_case
int int_compare(int lhs, int rhs);
```

#### Naming of Function Parameters

Function parameters are in camelCase.

```c
// GOOD: Function parameters are in camelCase
int plainFunction(int functionArgument)

// BAD: Function parameters are in snake_case
int plainFunction(int function_argument)
```

#### Naming of Local Variables

Local variables are in camelCase.

```c
int plainFunction(int functionArgument)
{
    // GOOD: Local variable is in camelCase
    int localVariable;

    // BAD: Local variable is in snake_case
    int local_variable;
}
```

#### Naming of Constants

Constant names are **always** in camelCase with prefix `k`.

```c
// GOOD: Constant name in camelCase with prefix `k`
static constexpr int kSomeConstant = 42;

// BAD: Constant name is not prefixed with `k`
static constexpr int someConstant = 42;

// BAD: Constant name in snake_case
static constexpr int some_constant = 42;

// BAD: Constant name in screaming SNAKE_CASE
static constexpr int SOME_CONSTANT = 42;

// GOOD: Constants (enum values) are in camelCase with prefix `k` (`k` + <enum type name> + <name>)
enum MyResult : uint8_t {
	kMyResultOk,
	kMyResultError,
}
```

#### Naming of Macros (`define`)

Names of defines are in screaming SNAKE_CASE.

```c
// GOOD: Macro name in screaming SNAKE_CASE.
#define IDENTITY_FUNCTION(x) (x)

// BAD: Macro name in camelCase.
#define identityFunction(x) (x)
```

#### Naming of Type Aliases (`typedef`)

1. Types defined with the `typedef` keyword are **always** in PascalCase.

```c
// GOOD: Type alias name in PascalCase
typedef int MyInt;

// BAD: Type alias name in camelCase
typedef int myInt;

// BAD: Type alias name in snake_case
typedef int my_int;

// GOOD: Type alias name of function pointer in PascalCase
typedef int (*CmpKeyFn)(const void* a, const void* b);

```

2. Type aliases of enum, struct types have the name of the source type.

```
// GOOD: Type alias name match enum type name
typedef enum MyEnum MyEnum;

// GOOD: Type alias name match enum type name
typedef enum MyEnum : uint8_t {
	kMyEnumValue1,
	kMyEnumValue2,
} MyEnum;

// GOOD: Type alias name match struct type name
typedef struct MyStruct MyStruct;

// GOOD: Type alias name match struct type name
typedef struct MyStruct {
    int a;
	int b;
} MyStruct;

// BAD: Type alias name of struct type does not match struct type name
typedef struct MyStruct StructTypeNameMismatch;

// BAD: Type alias name of enum type does not match enum type name
typedef enum MyEnum EnumTypeNameMismatch;
```

#### Naming of Global and Static Variables

- Global variables are in camelCase with prefix `g`
- Static variables are in camelCase with prefix `s`

```c
// GOOD: Global variable is in camelCase with prefix `g`
int gSomeGlobalVariable;

// GOOD: Static variable is in camelCase with prefix `s`
static int sSomeStaticVariable;

// BAD: Global variable is in snake_case
int some_global_variable;

// BAD: Static variable is in snake_case
static int some_static_variable;
```

### 2. Header Guards and Includes

- Use `#pragma once` as header guard on the first line (this extension is allowed)
- **Include what you use**: include the minimal headers needed; do not rely on transitive includes
- Include order: related header file → system header files → third-party header files → other project header files
- Use `<>` for system/third-party, `""` for project headers

Example: Include file order for `project/some_impl.c`
```c
#include "project/some_impl.h"  // 1. Related header file

#include <stddef.h>             // 2. System header file

#include <openssl/sha.h>        // 3. Third-party header file

#include "project/defs.h"       // 4. Other project header file
```

### 3. Public vs. Internal API

#### Public API

The public API have global linkage and is meant to be used by code external as well as internal to
the library.

#### Internal API

The internal API also have global linkage but is **only** meant to be used by other source files of
the same library.

Declarations of static functions are never placed in internal API header files, they are local to a
single source file. Note that `static inline` function definitions may be placed in header files,
they also have a function body.

Only use internal APIs for sharing declarations between source files withing the same library.
Prefer keeping implementation details to a single source file.

Use a suitable prefix for **non-static** internal APIs to avoid linking collisions.
I.e. avoid short generic names with high collision risk.

### 4. Scope

Use the minimum scope possible for all definitions.

- Prefer block scope over function scope for constants and variable definitions
- Prefer function scope over file scope for constants and variable definitions
- Prefer file scope (static) over global scope for all definitions

### 5. Memory Management

#### Heap Allocations

Heap allocations of the size of types are derived from the size of the dereferenced target pointer.

```c
// GOOD: Heap allocation size is derived from dereferenced target pointer
SomeStruct* x = malloc(sizeof(*x));

// BAD: Heap allocation size is derived from the type name of the target pointer
SomeStruct* x = malloc(sizeof(SomeStruct));
```

#### Memory Ownership

Every `create` function produces an owner; every `destroy` function consumes it. Document clearly in comments.

#### Null-safety

Public functions whos pointer arguments accept `nullptr` must be documented as such.
Use asserts at start of functions to check argument pointers for which `nullptr` is invalid; this clearly convays the API contract.

```c
void
myFunction(int* output)
{
    // GOOD: Assert check for pointer for which nullptr is invalid on function entry
	assert(output);

	*output = 42;
}
```

#### Variable Initialization

Initialize all scalar variables and pointers with sensible default values.

### 6. Error Handling

- Use a bool return value with false representing failure when a single error value is sufficient
- Return `nullptr` to indicate failure when the function naturally returns a pointer
- Define API specific enum values when more than a single error value is needed

  ```c
  typedef enum : uint8_t {
      kMyFunctionResultOk,
      kMyFunctionResultError,
      kMyFunctionResultBadParam,
      kMyFunctionResultNoMemory,
      kMyFunctionResultIoError,
  } MyFunctionResult;
  ```

### 7. Type Safety

- Use `stdbool.h` type `bool` (not `int` as bool)
- Use `stdint.h` types (`uint32_t`, `int64_t`) for fixed-width integers
- Use `inttypes.h` for printf fixed integer width format specifiers (e.g. PRIu64)
- Use format specifier `%zu` for size_t and `%p` for pointers
- Use `size_t` for sizes/lengths
- Apply const correctness:
  - Annotate every pointer parameter that the function does not modify with the `const` keyword
  - Annotate read-only local variables with the `const` keyword

```c
// GOOD: Pointer to data that is only read is annotated with the const keyword
uint32_t hashUpdate(uint32_t hash, const void* data, size_t dataLen);
```

- Avoid needless C++ cast from void* (this is a C project):

```c
static bool
someCallback(void* userData)
{
    // BAD: Needless C++ cast from void*
    SomeCallbackCtx* ctx = (SomeCallbackCtx*)userData;

    // GOOD: Cast from void* is avoided
    SomeCallbackCtx* ctx = userData;
}
```

### 8. Use of Constants

- **Never** use `define` for constants
- Prefer `constexpr` over `const` for constants
- The `constexpr` keyword is defined by the C23 standard (ISO/IEC 9899:2024)
- Use `static constexpr` in file scope, plain `constexpr` in function scope
- Use C23 explicitly sized `enum` for sets of related constants
- Use C23 `nullptr` as the "null" value of pointers
- The `nullptr` keyword is defined by the C23 standard (ISO/IEC 9899:2024)
- Use the suffix `U` for unsigned integer constant values

```c
// BAD: Constant is created with `define`
#define SOME_CONSTANT (42)
```

Constant Coding Conventions:

- Use the minimum scope possible for constant definitions
- Use named constants instead of duplicating magic values across the code; single unique localized magic values are fine
- Don't duplicate numeric values, use constants and derive related values from a single source

### 9. Pointer Style

The pointer symbol (`*`) is placed next to the type, not the variable or function parameter name.

```c
// GOOD: Pointer symbol next to type
int someFunc(const void* data, size_t dataLen);

// BAD: Pointer symbol next to function parameter name
int someFunc(const void* data, size_t dataLen);
```

### 10. Comments and Documentation

- The public API is documented using Go's (golang) concise documentation style with '//' as the line
  comment marker. Use plain English to describe behavior of functions and purpose of types with a
  line length of 80 characters.

```c
// GOOD: Update the hash with additional data. Returns true on success.
bool MyHash_update(MyHash* hash, const void* data, size_t dataLen);
```

- The overall high level functionality is documented in `README.md`.
- **Do not** use em-dash in comments. Use other punctuation such as comma, colon or semi-colon depending on the situation.

## Dependencies

- **Zero runtime dependencies** unless explicitly documented
- If third-party libraries are required, they must be:
  1. Listed in `README.md` and `meson.build`
  2. Optional with fallback implementations when possible
  3. Licenses compatible with the library's license

## Project Structure

```
mylib/
├── include/
│   └── mylib/
│       ├── foo.h            ← Public API of `foo.c`
│       └── mylib.h          ← Public API (optional single header or facade)
├── src/
│   ├── foo.c                ← Implementation source file
│   ├── foo_test.c           ← Unit tests of `foo.c`
│   ├── foo.h                ← Optional library internal API of `foo.c`
│   ├── bar.c                ← Implementation source file
│   ├── bar_test.c           ← Unit tests of `bar.c`
│   └── ...
├── examples/
│   └── mylib_example.c      ← Example program
├── Makefile                 ← Build wrapper
├── meson.build              ← Build configuration
├── README.md                ← Library documentation
├── LICENSE                  ← Library license conditions
└── AGENTS.md                ← This file
```

## Build System

**Meson** is used for building and testing the software.

A simple makefile wrapper provides easy access to release checks:

```bash
make clean       # Remove build artifacts
make format      # Format code
make lint        # Lint code
make test        # Run tests
make test-cover  # Run tests with coverage
make debug       # Debug build
make release     # Release build
make sanitize    # ASAN+UBSAN build
make cover       # Coverage build
```

**NOTE:** `make format` performs in-place updates of C source and header under the project root!

Build variants have separate output directories:

```
build/
├── coverage
├── debug
├── release
└── sanitize
```

## Unit Tests

Unit test conventsion:

- Every public function has at least one test covering the happy path
- Prefer testing the public API when conventient, else test internal API
- Every error-returning function have tests for each documented error condition
- Name test files to match source: `foo_test.c` for `foo.c`
- Unit tests are C functions in camelCase with prefix `test`
- Use simple assertion macros for tests (defined in `unittest.h`)
- The unit test API is defined in header file `unittest.h`

Example unit test assert function in `unittest.h`:
```c
#define ASSERT_EQ(a, b) do { \
    if ((a) != (b)) { fprintf(stderr, "FAIL: %s == %s at %s:%d\n", \
        #a, #b, __FILE__, __LINE__); exit(1); } } while(0)
```

Example unit test:
```c
void
testMyLibraryFunction()
{
    ASSERT_EQ(42, myLibraryFunction());
}
```

## Acceptance Criteria

Checks that MUST pass for a code change be considered complete:

- [ ] Public API is stable; no breaking changes unless explicitly permitted
- [ ] Code is formatted (`make format`)
- [ ] Code is linted (`make lint`) without reported violations
- [ ] Code is tested (`make test`) without errors
- [ ] Code builds without warnings (`make release`)

Consider running the checks after completed sub-tasks.
