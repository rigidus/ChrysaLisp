(import 'class/ref/ref.inc)

(def-class 'hash_set 'ref)
(def-method 'create 'class/hash_set/create 'static '(r0 r1) '(r0))
(def-method 'new 'class/hash_set/new 'static nil '(r0))
(def-method 'init 'class/hash_set/init 'static '(r0 r1 r2 r3))
(def-method 'get_bucket 'class/hash_set/get_bucket 'static '(r0 r1) '(r0 r1))
(def-method 'clear 'class/hash_set/clear 'static '(r0) '(r0))
(def-method 'for_each 'class/hash_set/for_each 'static '(r0 r1 r2) '(r0 r1 r2))
(def-method 'find 'class/hash_set/find 'static '(r0 r1) '(r0 r1 r2))
(def-method 'insert 'class/hash_set/insert 'static '(r0 r1) '(r0 r1 r2))
(def-method 'erase 'class/hash_set/erase 'static '(r0 r1 r2) '(r0))
(def-method 'copy 'class/hash_set/copy 'static '(r0 r1) '(r0 r1))

(def-method 'deinit 'class/hash_set/deinit 'override)

(def-struct 'hash_set 'ref)
	(ptr 'buckets)
	(ptr 'key_callback)
	(uint 'num_buckets)
(def-struct-end)