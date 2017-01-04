#pragma once

#include <QObject>
#include <QThread>
#include <QVector>
#include <QAtomicInt>

class Audio : public QThread {
    Q_OBJECT

public:
    Audio();

protected:
    void run();

private:
    QVector<float> m_chunk;
    QAtomicInt m_run;

public slots:
    void quit();
};