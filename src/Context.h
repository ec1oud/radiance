#pragma once

// A radiance context encapsulates
// all of the background stuff that goes on
// that allows VideoNodes to function as they do.

#include "VideoNode.h"

#include <QObject>

class QSettings;
class Audio;
class Timebase;
class OpenGLWorkerContext;

class Context : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString inputDeviceId READ inputDeviceId WRITE setInputDeviceId NOTIFY inputDeviceIdChanged)

public:
    Context(bool threaded=true);
   ~Context();

    bool threaded();
    Audio *audio();
    Timebase *timebase();
    OpenGLWorkerContext *openGLWorkerContext();

    QString inputDeviceId() const;
    void setInputDeviceId(QString inputDeviceId);

signals:
    void inputDeviceIdChanged();

protected:
    bool m_threaded;
    Audio *m_audio;
    Timebase *m_timebase;
    OpenGLWorkerContext *m_openGLWorkerContext;
};
