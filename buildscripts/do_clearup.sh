if [ -z "$1"  ]; then
	echo "Target Parameter required to build skeleton"
fi

TARGET_DIR="$1"

echo '#####################################################'
echo "-----Cleanup"
echo '#####################################################'
chroot-umount.sh "$TARGET_DIR" # Be sure all is unmounted in case of errors
umount -v "$TARGET_DIR"/var/cache/binpkgs

rm "$TARGET_DIR"/boot/*.old
rm "$TARGET_DIR"/etc/resolv.conf
rm -Rf "$TARGET_DIR"/root/*
rm -Rf "$TARGET_DIR"/root/.*
touch "$TARGET_DIR"/root/.keep
rm -Rf "$TARGET_DIR"/tmp/*
rm -Rf "$TARGET_DIR"/var/cache/edb/binhost
rm "$TARGET_DIR"/var/log/emerge*
rm "$TARGET_DIR"/var/log/portage/elog/summary.log
rm "$TARGET_DIR"/root/.bash_history
rm -Rf "$TARGET_DIR"/var/tmp/*
