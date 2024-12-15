#!/usr/bin/awk -f

{
	++G_gender[$1]
}

END {
	print "Genders:"
	for (_n in G_gender)
		print _n, G_gender[_n], sprintf("%.2f%%", G_gender[_n] / FNR * 100)
}
