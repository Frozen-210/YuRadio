#include <QLoggingCategory>
Q_LOGGING_CATEGORY(languageTranslatorLog, "YuRadio.LanguageTranslator")

#include <QGuiApplication>
#include <QLocale>
#include <QTranslator>

#include <QQmlApplicationEngine>

#include "languagetranslator.h"

using namespace Qt::StringLiterals;

LanguageTranslator::LanguageTranslator(QObject *parent)
    : QObject(parent), m_translator(new QTranslator(this)),
      m_qtTrasnlator(new QTranslator(this)) {
  QCoreApplication::installTranslator(m_translator);
  QCoreApplication::installTranslator(m_qtTrasnlator);

  QDirIterator it(u":/i18n"_s, {u"*"_s}, QDir::Files,
                  QDirIterator::Subdirectories);
  while (it.hasNext()) {
    QString translationFile = it.next();
    translationFile.truncate(translationFile.lastIndexOf('.'_L1));
    translationFile.remove(0, translationFile.indexOf('_'_L1) + 1);
    m_locales << translationFile;
  }
}

bool LanguageTranslator::load(const QString &language) {
  return load(QLocale(language));
}

bool LanguageTranslator::loadSystemLanguage() {
  return load(QLocale());
}

QStringList LanguageTranslator::locales() const {
  return m_locales;
};

bool LanguageTranslator::load(const QLocale &locale) {
  if (!m_qtTrasnlator->load(
        locale, u"qt"_s, u"_"_s,
        QLibraryInfo::path(QLibraryInfo::TranslationsPath))) {
    qCWarning(languageTranslatorLog)
      << "Failed to load builtin Qt translations";
  }

  if (m_translator->load(locale, u"YuRadio"_s, u"_"_s, u":/i18n"_s)) {
    qmlEngine(this)->retranslate();
    return true;
  }

  qCWarning(languageTranslatorLog) << "Failed to load YuRadio translations";

  return false;
}
