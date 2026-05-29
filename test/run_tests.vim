" ============================================================================
" ghostgit.vim - Test Runner (vader.vim)
" ============================================================================
"
" Prerequisites:
"   - Install vader.vim (https://github.com/junegunn/vader.vim)
"     e.g. via vim-plug: Plug 'junegunn/vader.vim'
"
" Project Structure Requirements:
"   - Tests should be placed in test/specs/*.vader
"   - Main plugin files should be in autoload/ghostgit/*.vim
"   - Plugin entry point should be in plugin/ghostgit.vim
"
" Usage (run from project root):
"   PROJ=$(pwd)
"   vim -c "set rtp^=\$PROJ" -c 'Vader! test/specs/*.vader' -c 'q!'
"
"   With neovim headless:
"   PROJ=$(pwd)
"   nvim --headless -c "set rtp^=\$PROJ" -c 'Vader! test/specs/*.vader' -c 'qall!'
"
"   Using Makefile (if available):
"   make test
"
"   Running individual test files:
"   vim -c "set rtp^=$(pwd)" -c 'Vader! test/specs/specific_test.vader' -c 'q!'
"
" Environment Variables:
"   GHOSTGIT_TEST_DIR - Set custom test directory (default: test/specs)
"   GHOSTGIT_VERBOSE   - Enable verbose output (default: 0)
"
" Test File Naming Convention:
"   - core_functions.vader    # Core functionality tests
"   - git_commands.vader      # Git command wrapper tests
"   - ui_components.vader     # UI component tests
"   - parser_logic.vader      # Parser logic tests
"   - integration_scenarios.vader # Integration scenario tests
"
" Test Structure Guidelines:
"   1. Each test file should focus on a single module/functionality
"   2. Use descriptive test case names
"   3. Include both positive and negative test cases
"   4. Mock external dependencies when possible
"   5. Clean up test artifacts after each test
"
" Available Vader Commands:
"   - Execute:   Runs a command in the test environment
"   - Assert:    Checks if a condition is true
"   - Save:      Saves the current buffer content
"   - Restore:   Restores a previously saved buffer state
"   - Do:        Executes arbitrary VimScript
"   - Log:       Outputs debug information
"
" Debugging Tips:
"   1. Add 'Log' statements to see variable values
"   2. Use 'Before' and 'After' blocks for setup/teardown
"   3. Run individual tests with ':Vader test/specs/specific_test.vader'
"   4. Use 'verbose' option to see detailed output
"
" Continuous Integration Setup:
"   For GitHub Actions, add to .github/workflows/test.yml:
"     - name: Run tests
"       run: |
"         vim -c "set rtp^=$(pwd)" -c 'Vader! test/specs/*.vader' -c 'q!' || exit 1
"
" Code Coverage:
"   Vader doesn't provide built-in coverage, but you can:
"   1. Manually instrument code with counters
"   2. Use external tools like covimerage for Python-based coverage
"
" Performance Testing:
"   For timing-sensitive tests, use Vader's time measurement features:
"   - Before: let start = reltime()
"   - After:  Log reltimestr(reltime(start))
"
" Troubleshooting:
"   - If Vader is not found, ensure it's in your runtime path
"   - If tests fail due to missing dependencies, install them first
"   - For path issues, verify the runtime path includes your project
"   - For async-related failures, consider using Vader's async features
"
" Example Test File Template:
"   ------------------------------------------------------------------------------
"   Execute (Setup test environment):
"     set rtp^=.
"
"   Before (Create test repo):
"     !mkdir -p /tmp/ghostgit_test
"     cd /tmp/ghostgit_test
"     !git init
"     !echo "test" > test.txt
"
"   After (Clean up):
"     !rm -rf /tmp/ghostgit_test
"
"   Execute (Test function):
"     let result = ghostgit#core#IsRepo()
"
"   Assert (Check result):
"     Assert result == 1
"   ------------------------------------------------------------------------------

" Configuration settings for test environment
function! ghostgit#test#Setup() abort
  " Add project to runtime path
  let $TEST_PROJ = getcwd()
  exec "set rtp+=" . $TEST_PROJ
  
  " Set verbose mode if requested
  if exists("$GHOSTGIT_VERBOSE") && $GHOSTGIT_VERBOSE
    set verbose=1
  endif
  
  " Set test directory
  let g:ghostgit_test_dir = get($GHOSTGIT_TEST_DIR, 'test/specs')
  
  " Ensure test directory exists
  if !isdirectory(g:ghostgit_test_dir)
    call mkdir(g:ghostgit_test_dir, 'p')
  endif
endfunction

" Run all tests
function! ghostgit#test#RunAll() abort
  call ghostgit#test#Setup()
  
  try
    " Run all test files
    exec 'Vader! ' . g:ghostgit_test_dir . '/*.vader'
    echo "All tests passed!"
  catch
    echo "Tests failed: " . v:exception
    return 1
  endtry
  
  return 0
endfunction

" Run specific test file
function! ghostgit#test#RunFile(filename) abort
  call ghostgit#test#Setup()
  
  let l:test_file = g:ghostgit_test_dir . '/' . a:filename
  if !filereadable(l:test_file)
    echo "Test file not found: " . l:test_file
    return 1
  endif
  
  try
    exec 'Vader! ' . l:test_file
    echo "Test passed: " . a:filename
  catch
    echo "Test failed: " . a:filename . " - " . v:exception
    return 1
  endtry
  
  return 0
endfunction

" List all available test files
function! ghostgit#test#List() abort
  call ghostgit#test#Setup()
  
  let l:test_files = glob(g:ghostgit_test_dir . '/*.vader', 0, 1)
  if empty(l:test_files)
    echo "No test files found in " . g:ghostgit_test_dir
    return
  endif
  
  echo "Available test files:"
  for l:file in l:test_files
    echo "  " . fnamemodify(l:file, ':t')
  endfor
endfunction