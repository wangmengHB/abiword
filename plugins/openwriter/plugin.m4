
openwriter_pkgs="$gsf_req"

OPENWRITER_CFLAGS=
OPENWRITER_LIBS=

if test "$enable_openwriter" == "yes"; then

PKG_CHECK_MODULES(OPENWRITER,[ $openwriter_pkgs ])

OPENWRITER_CFLAGS="$OPENWRITER_CFLAGS "'${WP_CPPFLAGS}'
OPENWRITER_LIBS="$OPENWRITER_LIBS "'${PLUGIN_LIBS}'

fi

AC_SUBST([OPENWRITER_CFLAGS])
AC_SUBST([OPENWRITER_LIBS])

