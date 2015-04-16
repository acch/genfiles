###
# Genfiles Makefile
# Compiles Perl script to executable binary
# Requires pp (perl-PAR-Packer)
#

genfiles : genfiles.pl
	pp -o genfiles -d -f Bleach genfiles.pl
