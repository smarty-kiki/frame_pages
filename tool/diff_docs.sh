#!/bin/bash

ROOT_DIR="$(cd "$(dirname $0)" && pwd)"/..

frame_dir=$1
docs_dir=$ROOT_DIR/docs/frame/1.0.0

sh $ROOT_DIR/tool/diff_doc.sh $frame_dir/cache/redis.php $docs_dir/cache.md
sh $ROOT_DIR/tool/diff_doc.sh $frame_dir/command.php $docs_dir/command.md
sh $ROOT_DIR/tool/diff_doc.sh $frame_dir/database/mysql.php $docs_dir/database.md
sh $ROOT_DIR/tool/diff_doc.sh $frame_dir/dialogue/beanstalk.php $docs_dir/dialogue.md
sh $ROOT_DIR/tool/diff_doc.sh $frame_dir/entity.php $docs_dir/orm.md
sh $ROOT_DIR/tool/diff_doc.sh $frame_dir/function.php $docs_dir/function.md
sh $ROOT_DIR/tool/diff_doc.sh $frame_dir/http/php_fpm/application.php $docs_dir/http.md
sh $ROOT_DIR/tool/diff_doc.sh $frame_dir/lock/cache.php $docs_dir/lock.md
sh $ROOT_DIR/tool/diff_doc.sh $frame_dir/log/file.php $docs_dir/log.md
sh $ROOT_DIR/tool/diff_doc.sh $frame_dir/otherwise.php $docs_dir/otherwise.md
sh $ROOT_DIR/tool/diff_doc.sh $frame_dir/queue/beanstalk.php $docs_dir/queue.md
sh $ROOT_DIR/tool/diff_doc.sh $frame_dir/spider/beanstalk.php $docs_dir/spider.md
sh $ROOT_DIR/tool/diff_doc.sh $frame_dir/storage/mongodb.php $docs_dir/storage.md
sh $ROOT_DIR/tool/diff_doc.sh $frame_dir/unitofwork.php $docs_dir/unitofwork.md
sh $ROOT_DIR/tool/diff_doc.sh $frame_dir/view_compiler/blade.php $docs_dir/view_compiler.md
