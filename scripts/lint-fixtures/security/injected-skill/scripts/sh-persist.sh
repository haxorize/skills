#!/bin/sh
# Fixture only — never executed. One annotated instance per alternative of the rule
# named in the file name; `# ruleid:` names the rule the next line must draw.
# ruleid: sh-persist
crontab - <<EOF
# ruleid: sh-persist
crontab /tmp/cron.txt
# ruleid: sh-persist
launchctl load ~/Library/LaunchAgents/com.example.plist
# ruleid: sh-persist
launchctl bootstrap gui/501 /tmp/com.example.plist
# The two path alternatives, each with a write beside it.
# ruleid: sh-persist
cp com.example.plist ~/Library/LaunchAgents/
# ruleid: sh-persist
cat plist.xml > ~/Library/LaunchAgents/com.example.plist
# ruleid: sh-persist
ln -s /tmp/x.plist ~/Library/LaunchAgents/x.plist
# ruleid: sh-persist
cat unit.service > ~/.config/systemd/user/example.service
# ruleid: sh-persist
mv example.service ~/.config/systemd/user/
# ruleid: sh-persist
install -m 644 example.service ~/.config/systemd/user/
# The rc-file write: append, truncate, tee, per file.
# ruleid: sh-persist
echo 'source /tmp/x.sh' >> ~/.zshrc
# ruleid: sh-persist
echo 'source /tmp/x.sh' >> "$HOME/.bashrc"
# ruleid: sh-persist
echo 'source /tmp/x.sh' >> ~/.bash_profile
# ruleid: sh-persist
echo 'source /tmp/x.sh' >> ~/.profile
# ruleid: sh-persist
echo 'source /tmp/x.sh' >> ~/.zprofile
# ruleid: sh-persist
echo 'export X=1' > ~/.bashrc
# ruleid: sh-persist
echo 'alias x=y' | tee -a ~/.zshrc
# ruleid: sh-persist
echo 'alias x=y' | tee ~/.zprofile
# ruleid: sh-persist
systemctl --user enable example.service
# ruleid: sh-persist
systemctl enable example.service
