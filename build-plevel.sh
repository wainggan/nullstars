cd ./tools/plevel
set RUST_BACKTRACE=1
cargo build
cp target/debug/plevel.exe target
cd ../..
