#include "androidradiocontroller.h"

#include "androidmediasessionimageprovider.h"
#include "nativemediacontroller.h"
#include "radioinforeaderproxyserver.h"

using namespace Qt::StringLiterals;

AndroidRadioController::AndroidRadioController(QObject *parent)
    : PlatformRadioController(parent),
      m_nativeController(NativeMediaController::instance()),
      m_mediaSessionImageProvider(new AndroidMediaSessionImageProvider(this)),
      m_proxyServer(new RadioInfoReaderProxyServer(true)) {

  connect(&m_proxyServerThread, &QThread::started, m_proxyServer,
          &RadioInfoReaderProxyServer::listen);
  connect(&m_proxyServerThread, &QThread::finished, m_proxyServer,
          &QObject::deleteLater);

  connect(this, &PlatformRadioController::audioStreamRecorderChanged, this,
          &AndroidRadioController::onAudioStreamRecorderChanged);

  connect(m_nativeController, &NativeMediaController::isLoadingChanged, this,
          [this](bool loading) { setIsLoading(loading); });
  connect(m_nativeController, &NativeMediaController::streamTitleChanged, this,
          [this](const QString &streamTitle) { setStreamTitle(streamTitle); });

  connect(m_nativeController, &NativeMediaController::playbackStateChanged,
          this, &AndroidRadioController::playbackStateChanged);
  connect(m_nativeController, &NativeMediaController::playerErrorChanged, this,
          &AndroidRadioController::playerError);

  m_proxyServerThread.setObjectName("RadioInfoReaderProxyServer Thread"_L1);
  m_proxyServer->moveToThread(&m_proxyServerThread);
  m_proxyServerThread.start();
}

AndroidRadioController::~AndroidRadioController() {
  m_proxyServerThread.quit();
  m_proxyServerThread.wait();
}

void AndroidRadioController::play() {
  m_nativeController->play();
}

void AndroidRadioController::stop() {
  m_nativeController->stop();
}

void AndroidRadioController::pause() {
  m_nativeController->pause();
}

void AndroidRadioController::setMediaItem(const MediaItem &mediaItem) {
  processMediaItem(mediaItem);

  PlatformRadioController::setMediaItem(mediaItem);
}

void AndroidRadioController::playbackStateChanged(int playbackStateCode) {
  Q_UNUSED(playbackStateCode);

  switch (playbackStateCode) {
    case NativeMediaController::PlayingState:
      setPlaybackState(RadioPlayer::PlayingState);
      break;
    case NativeMediaController::PausedState:
      setPlaybackState(RadioPlayer::PausedState);
      break;
    case NativeMediaController::StoppedState:
      setPlaybackState(RadioPlayer::StoppedState);
      break;
  }
}

static QString errorMessageForCode(int errorCode) {
  switch (errorCode) {
    case NativeMediaController::ERROR_CODE_IO_UNSPECIFIED:
    case NativeMediaController::ERROR_CODE_UNSPECIFIED:
      return "Unknown Error";
    case NativeMediaController::ERROR_CODE_REMOTE_ERROR:
      return "Internal Server Error";
    case NativeMediaController::ERROR_CODE_BEHIND_LIVE_WINDOW:
      return "Playback Behind Live Window";
    case NativeMediaController::ERROR_CODE_TIMEOUT:
      return "Connection Timeout";
    case NativeMediaController::ERROR_CODE_FAILED_RUNTIME_CHECK:
      return "Runtime Check Failed";
    case NativeMediaController::ERROR_CODE_IO_NO_PERMISSION:
      return "Permission denied";
    case NativeMediaController::ERROR_CODE_IO_NETWORK_CONNECTION_FAILED:
      return "Network Connection Failed";
    case NativeMediaController::ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT:
      return "Network Connection Timeout";
    case NativeMediaController::ERROR_CODE_IO_INVALID_HTTP_CONTENT_TYPE:
      return "Invalid HTTP Content Type";
    case NativeMediaController::ERROR_CODE_IO_BAD_HTTP_STATUS:
      return "Bad HTTP Status";
    case NativeMediaController::ERROR_CODE_IO_FILE_NOT_FOUND:
      return "File Not Found";
    case NativeMediaController::ERROR_CODE_IO_READ_POSITION_OUT_OF_RANGE:
      return "Read Position Out Of Range";
    case NativeMediaController::ERROR_CODE_IO_CLEARTEXT_NOT_PERMITTED:
      return "HTTP Traffic Not Supported";
    case NativeMediaController::ERROR_CODE_PARSING_CONTAINER_MALFORMED:
      return "Parsing Container Malformed";
    case NativeMediaController::ERROR_CODE_PARSING_MANIFEST_MALFORMED:
      return "Parsing Manifest Malformed";
    case NativeMediaController::ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED:
      return "Parsing Container Unsupported";
    case NativeMediaController::ERROR_CODE_PARSING_MANIFEST_UNSUPPORTED:
      return "Parsing Manifest Unsupported";

    case NativeMediaController::ERROR_CODE_DECODER_INIT_FAILED:
      return "Decoder Init Failed";
    case NativeMediaController::ERROR_CODE_DECODER_QUERY_FAILED:
      return "Decoder Query Failed";
    case NativeMediaController::ERROR_CODE_DECODING_FAILED:
      return "Decoder Decoding Failed";
    case NativeMediaController::ERROR_CODE_DECODING_FORMAT_EXCEEDS_CAPABILITIES:
      return "Decoder Format Exceeds Capabilities";
    case NativeMediaController::ERROR_CODE_DECODING_FORMAT_UNSUPPORTED:
      return "Decoder Format Unsupported";
    default:
      return "Unknown";
  }
}

void AndroidRadioController::playerError(int errorCode,
                                         const QString & /*message*/) {
  RadioPlayer::Error playerError = RadioPlayer::ResourceError;
  QString errorMessage = errorMessageForCode(errorCode);

  switch (errorCode) {
    case NativeMediaController::ERROR_CODE_UNSPECIFIED:
    case NativeMediaController::ERROR_CODE_REMOTE_ERROR:
    case NativeMediaController::ERROR_CODE_BEHIND_LIVE_WINDOW: {
      playerError = RadioPlayer::ResourceError;
      break;
    }

    case NativeMediaController::ERROR_CODE_TIMEOUT:
    case NativeMediaController::ERROR_CODE_FAILED_RUNTIME_CHECK: {
      playerError = RadioPlayer::ResourceError;
      break;
    }

    case NativeMediaController::ERROR_CODE_IO_NO_PERMISSION: {
      playerError = RadioPlayer::AccessDeniedError;
      break;
    }

    case NativeMediaController::ERROR_CODE_IO_UNSPECIFIED:
    case NativeMediaController::ERROR_CODE_IO_NETWORK_CONNECTION_FAILED:
    case NativeMediaController::ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT:
    case NativeMediaController::ERROR_CODE_IO_INVALID_HTTP_CONTENT_TYPE:
    case NativeMediaController::ERROR_CODE_IO_BAD_HTTP_STATUS:
    case NativeMediaController::ERROR_CODE_IO_FILE_NOT_FOUND:
    case NativeMediaController::ERROR_CODE_IO_READ_POSITION_OUT_OF_RANGE:
    case NativeMediaController::ERROR_CODE_IO_CLEARTEXT_NOT_PERMITTED: {
      playerError = RadioPlayer::NetworkError;
      break;
    }

    case NativeMediaController::ERROR_CODE_PARSING_CONTAINER_MALFORMED:
    case NativeMediaController::ERROR_CODE_PARSING_MANIFEST_MALFORMED:
    case NativeMediaController::ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED:
    case NativeMediaController::ERROR_CODE_PARSING_MANIFEST_UNSUPPORTED: {
      playerError = RadioPlayer::ResourceError;
      break;
    }

    case NativeMediaController::ERROR_CODE_DECODER_INIT_FAILED:
    case NativeMediaController::ERROR_CODE_DECODER_QUERY_FAILED:
    case NativeMediaController::ERROR_CODE_DECODING_FAILED:
    case NativeMediaController::ERROR_CODE_DECODING_FORMAT_EXCEEDS_CAPABILITIES:
    case NativeMediaController::ERROR_CODE_DECODING_FORMAT_UNSUPPORTED: {
      playerError = RadioPlayer::FormatError;
      break;
    }
  }

  setError(playerError, errorMessage);
}

void AndroidRadioController::setVolume(float volume) {
  m_nativeController->setVolume(volume);
  PlatformRadioController::setVolume(volume);
}

void AndroidRadioController::processMediaItem(const MediaItem &mediaItem) {
  if (!mediaItem.source.isValid()) {
    return;
  }
  m_nativeController->setAuthor(mediaItem.author);

  m_mediaSessionImageProvider->setImageSource(mediaItem.artworkUri);
  m_nativeController->setArtworkUri(m_mediaSessionImageProvider->imageUrl());

  /* NOTE: Set source lastly */
  m_proxyServer->setTargetSource(mediaItem.source);
  m_nativeController->setSource(m_proxyServer->sourceUrl());
}

bool AndroidRadioController::canHandleMediaKeys() const {
  return true;
}

void AndroidRadioController::onAudioStreamRecorderChanged() {
  connect(m_recorder, &AudioStreamRecorder::recordingChanged, this, [this]() {
    m_proxyServer->enableCapturing(m_recorder->recording());
  });
  connect(m_proxyServer, &RadioInfoReaderProxyServer::bufferCaptured,
          m_recorder,
          [this](const QByteArray &buffer, const QString &streamTitle) {
    m_recorder->processBuffer(buffer, m_mediaItem.source, streamTitle);
  });
  connect(m_proxyServer, &RadioInfoReaderProxyServer::mimeTypeChanged,
          m_recorder, [this](const QMimeType &mimeType) {
    if (mimeType.isValid() && !mimeType.preferredSuffix().isEmpty()) {
      m_recorder->setPreferredSuffix(mimeType.preferredSuffix());
    }
  });
}
