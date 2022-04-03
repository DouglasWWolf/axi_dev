@echo off
set project=axi_dev
git add %project%.hw
git add %project%.sim
git add %project%.srcs
git add %project%.xpr
git add push.bat README.md
git commit -m "See History.h for changes"
git push origin main