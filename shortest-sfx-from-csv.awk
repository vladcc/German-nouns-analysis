#!/usr/bin/awk -f

# <main>

# Expected input
# suffix;len;count;%count;der;die;das;%der;%die;%das;rev

# <const>
function SFX_PFT_ROOT() {return "@"}
function SFX_END()      {return "-"}
# </const>

# <sfx-pft>
function sfx_pft_init() {
	pft_init(_B_sfx_pft)
}

function sfx_pft_insert(    _rev_sfx, _arr, _len) {
	_rev_sfx = $NF
	_B_sfx_input_cache[_rev_sfx] = $0

	_rev_sfx = (SFX_PFT_ROOT() _rev_sfx)

	_len = split(_rev_sfx, _arr, "")
	pft_insert(_B_sfx_pft, pft_arr_to_pft_str(_arr, _len))
}

function sfx_pft_traverse() {
	_sfx_pft_traverse(SFX_PFT_ROOT(), "")
}

function _sfx_pft_traverse(root, rev_sfx,    _arr, _len, _i, _get, _ch) {

	if (!pft_has(_B_sfx_pft, root))
		return

	if (!(_get = pft_get(_B_sfx_pft, root)))
		return

	if (!pft_path_has(_get, SFX_END())) {
		_len = pft_split(_arr, _get)
		for (_i = 1; _i <= _len; ++_i) {
			_ch = _arr[_i]
			_sfx_pft_traverse(pft_cat(root, _ch), (rev_sfx _ch))
		}
	} else {
		rev_sfx = (rev_sfx SFX_END())
		if (rev_sfx in _B_sfx_input_cache)
			print _B_sfx_input_cache[rev_sfx]
	}
}

function sfx_pft_dump() {
	pft_print_dump(_B_sfx_pft)
}
# </sfx-pft>

# <awk>
BEGIN {
	FS=";"
	sfx_pft_init()
}

1 == FNR && "suffix" == $1 {
	G_hdr = $0
	next
}

{
	if (PassThrough)
		print $0
	else
		sfx_pft_insert()
}

END {
	if (G_hdr)
		print G_hdr

	sfx_pft_traverse()
}
# </awk>
# </main>

#@ <awklib_prefix_tree>
#@ Library: pft
#@ Description: A prefix tree implementation. E.g. conceptually, if you
#@ insert "this" and "that", you'd get:
#@ pft["t"] = "h"
#@ pft["th"] = "ia"
#@ pft["thi"] = "s"
#@ pft["this"] = ""
#@ pft["tha"] = "t"
#@ pft["that"] = ""
#@ However, all units must be separated by PFT_SEP(), so in this case
#@ "this" should be ("t" PFT_SEP() "h" PFT_SEP() "i" PFT_SEP() "s").
#@ Similar for "that". PFT_SEP() is a non-printable character. To make
#@ any key or value from a pft printable, use pft_pretty().
#@ Version: 1.3
##
## Vladimir Dinev
## vld.dinev@gmail.com
## 2022-01-18
#@

# "\034" is inlined as a constant; make sure it's in sync with PFT_SEP()
function _PFT_LAST_NODE() {

	return "\034[^\034]+$"
}

# <public>
#
#@ Description: The prefix tree path delimiter.
#@ Returns: Some non-printable character.
#
function PFT_SEP() {

	return "\034"
}

#
#@ Description: Clears 'pft'.
#@ Returns: Nothing.
#@ Complexity: O(1)
#
function pft_init(pft) {

	pft[""]
	delete pft
}

#
#@ Description: Inserts 'path' in 'pft'. 'path' has to be a PFT_SEP() delimited
#@ string.
#@ Returns: Nothing.
#@ Complexity: O(n)
#
function pft_insert(pft, path,    _val) {
# inserts "a.b.c", "a.x.y" backwards, so you get
# pft["a.b.c"] = ""
# pft["a.b"] = "c"
# pft["a"] = "b"
# pft["a.x.y"] = ""
# pft["a.x"] = "y"
# pft["a"] = "b.x"

	if (!path)
		return

	if (!_pft_add(pft, path, _val))
		return

	if (!match(path, _PFT_LAST_NODE()))
		return

	_val = substr(path, RSTART+1)
	path = substr(path, 1, RSTART-1)

	pft_insert(pft, path, _val)
}

#
#@ Description: If 'path' exists in 'pft', makes 'path' and all paths stemming
#@ from 'path' unreachable. 'path' has to be a PFT_SEP() delimited string.
#@ Returns: Nothing.
#@ Complexity: O(n)
#
function pft_rm(pft, path,    _last, _start_last, _no_tail, _no_tail_val) {

	if (pft_has(pft, path)) {

		delete pft[path]

		if (match(path, _PFT_LAST_NODE())) {

			_last = substr(path, RSTART+1)
			_no_tail = substr(path, 1, RSTART-1)

			_no_tail_val = (PFT_SEP() pft[_no_tail] PFT_SEP())

			_start_last = index(_no_tail_val, (PFT_SEP() _last PFT_SEP()))

			_no_tail_val = ( \
				substr(_no_tail_val, 1, _start_last-1) \
				PFT_SEP() \
				substr(_no_tail_val, _start_last + length(_last) + 2) \
			)
			gsub(("^" PFT_SEP() "|" PFT_SEP() "$"), "", _no_tail_val)

			pft[_no_tail] = _no_tail_val
		}
	}
}

#
#@ Description: Marks 'path' in 'pft', so pft_is_marked() will return
#@ 1 when asked about 'path'. The purpose of this is so also
#@ intermediate paths, and not only leaf nodes, can be considered during
#@ traversal. E.g. if you insert "this", "than", and "thank" in 'pft'
#@ and want to get these words out again, when you traverse only "this"
#@ and "thank" will be leaf nodes in the pft. Unless "than" is somehow
#@ marked, you will have no way to know "than" is actually a word, and
#@ not only an intermediate path to "thank", like "tha" would be.
#@ Returns: Nothing.
#@ Complexity: O(1)
#
function pft_mark(pft, path) {

	pft[(_PFT_MARK_SEP() path)]
}

#
#@ Description: Indicates if 'path' is marked in 'pft'.
#@ Returns: 1 if it is, 0 otherwise.
#@ Complexity: O(1)
#
function pft_is_marked(pft, path) {

	return ((_PFT_MARK_SEP() path) in pft)
}

#
#@ Description: Unmarks 'path' from 'pft' if it was previously marked.
#@ Returns: Nothing.
#@ Complexity: O(1)
#
function pft_unmark(pft, path) {

	if (pft_is_marked(pft, path))
		delete pft[(_PFT_MARK_SEP() path)]
}

#
#@ Description: Retrieves 'key' from 'pft'.
#@ Returns: pft[key] if 'key' exists in 'pft', the empty string
#@ otherwise. Use only if pft_has() has returned 1.
#@ Complexity: O(1)
#
function pft_get(pft, key) {

	return pft_has(pft, key) ? pft[key] : ""
}

#
#@ Description: Indicates whether 'key' exists in 'pft'.
#@ Returns: 1 if 'key' is found in 'pft', 0 otherwise.
#@ Complexity: O(1)
#
function pft_has(pft, key) {

	return (key in pft)
}

#
#@ Description: Splits 'pft_str' in 'arr' using PFT_SEP() as a
#@ separator. I.e. Splits what pft_get() returns.
#@ Returns: The length of 'arr'.
#@ Complexity: O(n)
#
function pft_split(arr, pft_str) {

	return split(pft_str, arr, PFT_SEP())
}


#
#@ Description: Splits 'pft_str', finds out if 'node' exists in
#@ the array created by the split.
#@ Returns: 1 if 'node' is a path in 'pft_str', 0 otherwise.
#@ Complexity: O(n)
#
function pft_path_has(pft_str, node) {

	return (!!index((PFT_SEP() pft_str PFT_SEP()), (PFT_SEP() node PFT_SEP())))
}

#
#@ Description: Turns 'arr' into a PFT_SEP() delimited string.
#@ Returns: The pft string representation of 'arr'.
#@ Complexity: O(n)
#
function pft_arr_to_pft_str(arr, len,    _i, _str) {

	_str = ""
	for (_i = 1; _i < len; ++_i)
		_str = (_str arr[_i] PFT_SEP())
	if (_i == len)
		_str = (_str arr[_i])
	return _str
}

#
#@ Description: Delimits the strings 'a' and 'b' with PFT_SEP().
#@ Returns: If only b is empty, returns a. If only a is empty, returns
#@ b. If both are empty, returns the empty string. Returns
#@ (a PFT_SEP() b) otherwise.
#@ Complexity: O(awk-concatenation)
#
function pft_cat(a, b) {

	if (("" != a) && ("" != b)) return (a PFT_SEP() b)
	if ("" == b) return a
	if ("" == a) return b
	return ""
}

#
#@ Description: Replaces all internal separators in 'pft_str' with
#@ 'sep'. If 'sep' is not given, "." is used.
#@ Returns: A printable representation of 'pft_str'.
#@ Complexity: O(n)
#
function pft_pretty(pft_str, sep) {

	gsub((PFT_SEP() "|" _PFT_MARK_SEP()), ((!sep) ? "." : sep), pft_str)
	return pft_str
}

#
#@ Description: Builds a string by performing a depth first search
#@ traversal of 'pft' starting from 'root'. The end result is all marked
#@ and leaf nodes subseparated by 'subsep' in their order of insertion
#@ separated by 'sep'. If 'sep' is not given, " " is used. If 'subsep'
#@ is not given, PFT_SEP() is removed from the node strings. E.g. for
#@ the words "this" and "that", if 'sep' is " -> "
#@ If 'subsep' is blank, the result shall be
#@ "this -> that"
#@ If 'subsep' is '-', the result shall be
#@ "t-h-i-s -> t-h-a-t"
#@ 'sep' does not appear after the last element.
#@ Returns: A string representation 'pft'.
#@ Complexity: O(n)
#
function pft_to_str_dfs(pft, root, sep, subsep,    _arr, _i, _len, _str,
_tmp, _get) {

	if (!pft_has(pft, root))
		return ""

	if (!(_get = pft_get(pft, root)))
		return root

	if (pft_is_marked(pft, root))
		_str = root

	if (!sep)
		sep = " "

	_tmp = ""
	_len = pft_split(_arr, _get)
	for (_i = 1; _i <= _len; ++_i) {

		if (_tmp = pft_to_str_dfs(pft, pft_cat(root, _arr[_i]),
			sep, subsep)) {
			_str = (_str) ? (_str sep _tmp) : _tmp
		}
	}

	gsub(PFT_SEP(), subsep, _str)
	return _str
}

#
#@ Description: Prints the string representation of 'pft' to stdout as
#@ returned by pft_to_str_dfs().
#@ Returns: Nothing.
#@ Complexity: O(n)
#
function pft_print_dfs(pft, root, sep, subsep) {

	print pft_to_str_dfs(pft, root, sep, subsep)
}

#
#@ Description: Returns the dump of 'pft' as a single multi line string
#@ in the format "pft[<key>] = <val>" in no particular order. Marked
#@ nodes always begin with 'sep'.
#@ Returns: Nothing.
#@ Complexity: O(n)
#
function pft_str_dump(pft, sep,    _n, _str, _ret) {

	for (_n in pft) {
		_str = sprintf("pft[\"%s\"] = \"%s\"",
				pft_pretty(_n, sep), pft_pretty(pft[_n], sep))
		_ret = (_ret) ? (_ret "\n" _str) : _str
	}
	return _ret
}

#
#@ Description: Prints the dump of 'pft to stdout as returned by
#@ pft_str_dump().
#@ Returns: Nothing.
#@ Complexity: O(n)
#
function pft_print_dump(pft, sep) {

	print pft_str_dump(pft, sep)
}
# </public>

function _pft_add(pft, key, val,    _path) {

	if ((_path = pft_get(pft, key))) {

		if (val && !pft_path_has(_path, val))
			val = pft_cat(_path, val)
		else
			return 0
	}

	pft[key] = val
	return 1
}

function _PFT_MARK_SEP() {return "mark\006"}
#@ </awklib_prefix_tree>
