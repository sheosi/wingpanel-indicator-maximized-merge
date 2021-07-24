project('wingpanel-maximized-merge', 'vala', 'c')

i18n = import('i18n')
gettext_name = meson.project_name() + '-indicator'

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_name), language:'c')

wingpanel_dep = dependency('wingpanel-2.0')

extra_vapis = join_paths(meson.current_source_dir(), 'vapis')
add_project_arguments(['--vapidir', extra_vapis], language: 'vala')
add_project_arguments('--enable-experimental-non-null', language: 'vala')
add_global_arguments(['-D', 'XCONN_FAST'], language: 'vala')

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('granite'),
    dependency('gtk+-3.0'),
    dependency('libxml-2.0'),
    dependency('xcb'),
    wingpanel_dep
]

files = [
    'src/Indicator.vala',
    'src/BorderRemover.vala',
    'src/XConn.vala',
    'src/Widgets/DisplayWidget.vala'
]

shared_module(
    meson.project_name(),
    files,
    dependencies: dependencies,
    install: true,
    install_dir : wingpanel_dep.get_pkgconfig_variable('indicatorsdir')
)

subdir('po')
