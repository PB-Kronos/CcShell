# AI Usage Policy

This project uses AI as a development aid, not as a replacement for review or ownership.

## Allowed Uses

- Drafting code, scripts, docs, wiki pages, and templates
- Helping debug errors and trace filesystem or package issues
- Suggesting package layouts, installer logic, and UI flow
- Summarizing logs, traces, and repository context
- Generating repetitive boilerplate when the intended behavior is already known

## Restrictions

- Do not paste secrets, tokens, passwords, private keys, or personal data into AI prompts.
- Do not accept AI output blindly. Review any code before using it.
- Do not use AI to make security-sensitive decisions without human review.
- Do not let AI perform destructive actions, publish changes, or modify release-critical files without checking the result first.
- Do not use AI-generated code that depends on unverified assumptions about the runtime or filesystem layout.

## Package and Contribution Rules

- If a package or feature was AI-assisted, that is fine, but the final result must still be understood and verified by the maintainer.
- Package submissions should include a short note if AI was used in the implementation.
- AI may help write package scripts, but install and remove behavior must be tested manually.

## Operational Rule

If AI output conflicts with current repo state, the repo state wins.
