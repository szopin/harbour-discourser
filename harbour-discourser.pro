# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-discourser

CONFIG += sailfishapp_qml

DISTFILES += qml/harbour-discourser.qml \
    qml/cover/CoverPage.qml \
    qml/forums.js \
    qml/pages/About.qml \
    qml/pages/CategorySelect.qml \
    qml/pages/FirstPage.qml \
    qml/pages/OpenLink.qml \
    qml/pages/SearchPage.qml \
    qml/pages/ThreadView.qml \
    qml/pages/webView.qml \
    qml/pages/worker.js \
    rpm/harbour-discourser.changes.in \
    rpm/harbour-discourser.changes.run.in \
    rpm/harbour-discourser.spec \
    translations/*.ts \
    harbour-discourser.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += \
    translations/harbour-discourser-ru.ts \
    translations/harbour-discourser-sv.ts \
    translations/harbour-discourser-zh_CN.ts

