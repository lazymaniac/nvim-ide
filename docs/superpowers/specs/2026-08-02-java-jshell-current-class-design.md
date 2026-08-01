# Run Current Java Class in JShell Design

Date: 2026-08-02

## Goal

Add a Java-buffer keybinding that saves and compiles the current class, opens a project-aware JShell, invokes that class's `main(String[])` method, and leaves the shell open for follow-up experiments.

## User experience

- `<leader>cJ` runs the current Java class in JShell.
- `<leader>cj` keeps its existing behavior: open an interactive project-aware JShell without running a class.
- Invoking `<leader>cJ` saves the current buffer with `:update` before compilation.
- A successful run opens JShell in a bottom split, submits `fully.qualified.ClassName.main(new String[0]);`, and leaves the terminal interactive.
- The mapping is buffer-local and is installed only after JDTLS attaches to a Java buffer.

## Execution flow

The runner lives in `lua/nv_ide/java.lua` so the asynchronous behavior can be tested independently of plugin setup.

1. Capture and validate the current buffer. It must be a named, writable Java source buffer with an attached JDTLS client.
2. Save pending changes with `:update`. If saving fails, stop before requesting a build.
3. Resolve the fully qualified class name from the saved buffer. Parse the saved source with Tree-sitter and capture the invocation only when a public top-level type declares a conventional `public static void main(String[])` method (one-dimensional array or varargs spelling). Requiring a public declaring type ensures the JShell snippet can access it from its generated package.
4. Ask the attached JDTLS client for an incremental `java/buildWorkspace` build and wait for its response. Continue only when the returned workspace-build status is `SUCCEED` (`1`).
5. Execute `vscode.java.resolveMainClass` through the same JDTLS client and require exactly one entry whose class portion matches the current class. A module-qualified result such as `module.name/package.Class` matches `package.Class`, while its original value is retained for later JDTLS requests. This provides the project name, prevents launching a class without a recognized `main` method, and avoids choosing arbitrarily when separate projects contain the same fully qualified class.
6. Resolve that main class's runtime classpath/module path with `vscode.java.resolveClasspath` and its selected Java executable with `vscode.java.resolveJavaExecutable`. The runner uses callback-total wrappers around the same commands used by nvim-jdtls so a failed resolution can always release its in-progress guard; the configured JDTLS runtime setting is the compatibility fallback.
7. Derive `jshell` from the selected Java executable's `bin` directory. Fall back to `jshell` on `PATH` only when a sibling executable is unavailable.
8. Open a terminal split with argument-vector process spawning. Supply the resolved classpath and module path with platform-aware path separators, add all application modules when a module path exists, then send the exact main invocation through the terminal channel.

Every asynchronous callback uses the originally captured buffer and JDTLS client. Changing windows or buffers while the build runs must not redirect resolution to a different project.

## Safety and compatibility

- Commands are passed as argument arrays; no shell command or user-controlled source text is interpolated into a shell string.
- The generated invocation contains only the class name resolved from the current filename/package and accepted by JDTLS as a main class.
- Existing interactive JShell, compile, build, test, and debugger mappings remain unchanged.
- Only one run request is allowed per buffer at a time. A second keypress reports that the build is already in progress instead of starting an overlapping pipeline.
- The asynchronous pipeline watches JDTLS detachment and source-buffer closure and has a 120-second watchdog. Any of those termination paths cancels outstanding LSP requests, releases the per-buffer guard, and makes every late callback a no-op.
- The runner uses runtime paths returned by JDTLS rather than Neovim's startup working directory or a globally assumed build directory.
- Classpath and module-path lists are filtered to readable files/directories before launch.
- Java 25+ no-argument and instance `main` methods may be recognized by the debug adapter, but are rejected because the approved JShell invocation targets the conventional static `main(String[])` contract.
- Named-module launches use `--add-modules ALL-MODULE-PATH`; packages that are not exported by their module remain subject to Java's normal module-access rules.
- The implementation targets the configuration's Neovim 0.12 minimum and uses terminal jobs without deprecated command-string APIs.

## Error handling

The runner stops and reports a concise actionable notification when:

- the buffer is unnamed, is not a Java source file, or cannot be saved;
- no JDTLS client is attached;
- the JDTLS build request errors, is cancelled, or returns a non-success status;
- JDTLS detaches, the source buffer closes, or an LSP stage exceeds the watchdog;
- JDTLS does not recognize the current class as a main class;
- the current type is not public or lacks a directly invocable `public static void main(String[])` or `main(String...)` declaration;
- two JDTLS projects report the same fully qualified main class;
- Java executable or classpath resolution fails;
- JDTLS returns no readable classpath or module-path entry;
- JShell cannot be found or its terminal job cannot start.

Build failures direct the user to the existing `<leader>cc` compile workflow for detailed diagnostics. The runner never opens a shell or executes stale bytecode after a failed build.

## Verification

Headless tests cover:

- save-before-build ordering;
- the exact incremental build request and captured buffer/client usage;
- successful matching of the current fully qualified class among multiple main classes;
- rejection of missing JDTLS, failed saves, failed builds, and classes without `main`;
- classpath/module-path filtering and platform-aware joining;
- argument-vector JShell launch and the exact `main(new String[0])` input;
- re-entry protection while an asynchronous run is active;
- timeout/detach cancellation, guard release, and ignored late callbacks;
- syntax-aware acceptance of standard array/varargs mains and rejection of flexible or misleading signatures;
- preservation of `<leader>cj` plus the new buffer-local `<leader>cJ` mapping.

Final verification includes Lua compilation, the focused Java/headless tests, the complete headless suite, and `git diff --check`.
