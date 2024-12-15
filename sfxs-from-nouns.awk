#!/usr/bin/awk -f

function pcent(a, b) {
	return sprintf("%.2f", (a/b*100))
}
function rev_str(str,    _arr, _i, _end, _ret) {
	_end = split(str, _arr, "")
	for (_i = _end; _i >= 1; --_i)
		_ret = (_ret _arr[_i])
	return _ret
}

function sfx_add(sfx, gender) {
	sfx = ("-" sfx)

	++_B_sfx_count
	_B_sfx_set[sfx]

	++_B_sfx_tbl[("count: " sfx)]
	++_B_sfx_tbl[(gender ": " sfx)]
}
function sfx_report(    _sfx, _len, _count, _der, _die, _das, _arr, _i, _end) {
	OFS=";"

	print "suffix", "len",      \
		"count", "%count",      \
		"der", "die", "das",    \
		"%der", "%die", "%das", \
		"rev"

	for (_sfx in _B_sfx_set) {
		_len = length(_sfx)-1
		_count = _B_sfx_tbl[("count: " _sfx)]+0
		_der = _B_sfx_tbl[("der: " _sfx)]+0
		_die = _B_sfx_tbl[("die: " _sfx)]+0
		_das = _B_sfx_tbl[("das: " _sfx)]+0

		print _sfx, _len,                                                  \
			_count, pcent(_count, _B_sfx_count),                           \
			_der, _die, _das,                                              \
			pcent(_der, _count), pcent(_die, _count), pcent(_das, _count), \
			rev_str(_sfx)
	}
}

function get_sfxs(gender, word,    _len, _sfx, _i) {

	_len = length(word)
	for (_i = 1; _i <= 5; ++_i) {
		if (_len <= _i)
			break

		_sfx = substr(word, _len-_i+1, _i)
		sfx_add(_sfx, gender)
	}
}

{
	get_sfxs($1, $2)
}

END {
	sfx_report()
}
