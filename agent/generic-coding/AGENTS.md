# Project

INTRODUCTION

See README.md for an overview.

## Rules of Engagement

### Documentation style

#### General writing

- Use plain language without contrived metaphors.
- Don't use abbreviations (except for the exempted ones).
- Consider the document's scope: does the information belong there?

#### Code comments

- Use Go's API comment style: lead with the name of the function or type it applies to.
- Comment on the current design, not its history.
- Don't refer to external documents or task instructions in comments.

#### Exempted abbreviations

- E.g. (exempli gratia: for example).
- I.e. (id est: that is).
- API (application programming interface).
- Established protocols, products or company names.

### Design methodologies

- Don't abbreviate function or type names.
- Use consistent naming of functions, types and variables.
- Use the minimum scope possible for function, type and variable definitions.
- Use pure functions and immutable data definitions when appropriate.
- Consider the responsibilities of code modules and strive for natural API semantics.
- Avoid duplication of code and data.
- Avoid inline magic constants: name constants to provide context.

### Unit testing

- Group tests by the functionality being tested.
- Keep tests focused to a single property.
- Use data tables for testing the same logic with multiple inputs.
- Minimize the number of tests needed to achieve test coverage.
- Comment each test function, explaining its purpose.
- When adding a test specifically for a bug fix, make sure it fails without the fix in place.
