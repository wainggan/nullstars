cd .\tools\plevel
set RUST_BACKTRACE=1
cargo build
cd ..\..
.\tools\plevel\target\debug\plevel.exe map src\datafiles
