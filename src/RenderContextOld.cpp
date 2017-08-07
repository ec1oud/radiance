#include "RenderContextOld.h"
#include "main.h"
#include <QOpenGLFunctions>
#include <QDebug>
#include <QThread>
/*static*/ QString RenderContextOld::defaultVertexShaderSource()
{
    return QString(
    "#version 130\n"
//    "#extension GL_ARB_shading_language_420pack : enable\n"
//    "const vec2 varray[4] = { vec2( 1., 1.),vec2(1., -1.),vec2(-1., 1.),vec2(-1., -1.)};\n"
    "varying vec2 coords;\n"
    "void main() {\n"
    "    vec2 vertex;\n"
    "    switch(gl_VertexID) {\n"
    "    case 0: vertex = vec2(1.,1.);break;\n"
    "    case 1: vertex = vec2(1.,-1.);break;\n"
    "    case 2: vertex = vec2(-1.,1.);break;\n"
    "    case 3: vertex = vec2(-1.,-1.);break;\n"
    "    default:vertex = vec2(0.,0.);break;\n"
    "    }\n"
//    "    vec2 vertex = varray[gl_VertexID];\n"
    "    gl_Position = vec4(vertex,0.,1.);\n"
    "    coords = vertex;\n"
    "}");

}
RenderContextOld::RenderContextOld()
    : context(nullptr)
    , surface(nullptr)
    , timer(nullptr)
    , m_premultiply(nullptr)
    , m_outputCount(2)
    , m_currentSyncSource(NULL)
    , m_rendering(2)
    , m_noiseTextures(m_outputCount)
    , m_blankFbo()
    , m_framePeriodLPF(0)
{
    connect(this, &RenderContextOld::addVideoNodeOldRequested, this, &RenderContextOld::addVideoNodeOld, Qt::QueuedConnection);
    connect(this, &RenderContextOld::removeVideoNodeOldRequested, this, &RenderContextOld::removeVideoNodeOld, Qt::QueuedConnection);
    connect(this, &RenderContextOld::renderRequested, this, &RenderContextOld::render, Qt::QueuedConnection);
}

RenderContextOld::~RenderContextOld() {
    delete surface;
    surface = 0;
    delete context;
    context = 0;
    delete m_premultiply;
    m_premultiply = 0;
//    delete m_blankFbo;
//    m_blankFbo = 0;
    foreach(auto t, m_noiseTextures) delete t;
    m_noiseTextures.clear();
}

void RenderContextOld::start() {
    qDebug() << "Calling start from" << QThread::currentThread();
    context = new QOpenGLContext(this);
    auto scontext = QOpenGLContext::globalShareContext();
    if(scontext) {
        context->setFormat(scontext->format());
        context->setShareContext(scontext);
    }

    context->create();

    // Creating a QOffscreenSurface with no window
    // may fail on some platforms
    // (e.g. wayland)
    surface = new QOffscreenSurface();
    surface->setFormat(context->format());
    surface->create();

    elapsed_timer.start();
}

void RenderContextOld::checkLoadShaders() {
    if(m_premultiply != nullptr) return;

    auto program = m_premultiply;
    program = new QOpenGLShaderProgram(this);
    program->addShaderFromSourceCode(QOpenGLShader::Vertex,
                                     defaultVertexShaderSource());
    program->addShaderFromSourceCode(QOpenGLShader::Fragment,
                                       "varying vec2 coords;"
                                       "uniform sampler2D iFrame;"
                                       "void main() {"
                                       "    vec4 l = texture2D(iFrame, 0.5 * (coords + 1.));"
                                       "    gl_FragColor = vec4(l.rgb * l.a, l.a);"
                                       "}");
    program->link();
    m_premultiply = program;
}

QOpenGLTexture *RenderContextOld::noiseTexture(int i) {
    return m_noiseTextures.at(i);
}

std::shared_ptr<QOpenGLFramebufferObject> &RenderContextOld::blankFbo() {
    return m_blankFbo;
}

void RenderContextOld::update() {
    if(m_rendering.tryAcquire()) {
        emit renderRequested();
    }
}

void RenderContextOld::checkCreateNoise() {
    for(int i=0; i<m_outputCount; i++) {
        auto tex = m_noiseTextures.at(i);
        if(tex &&
           tex->width() == fboSize(i).width() &&
           tex->height() == fboSize(i).height()) {
            continue;
        }
        delete tex;
        tex = new QOpenGLTexture(QOpenGLTexture::Target2D);
        tex->setSize(fboSize(i).width(), fboSize(i).height());
        tex->setFormat(QOpenGLTexture::RGBA8_UNorm);
        tex->allocateStorage(QOpenGLTexture::RGBA, QOpenGLTexture::UInt8);
        tex->setMinMagFilters(QOpenGLTexture::Linear, QOpenGLTexture::Linear);
        tex->setWrapMode(QOpenGLTexture::Repeat);

        auto byteCount = fboSize(i).width() * fboSize(i).height() * 4;
        auto data = std::make_unique<uint8_t[]>(byteCount);
        qsrand(1);
        std::generate(&data[0],&data[0] + byteCount,qrand);
        tex->setData(QOpenGLTexture::RGBA, QOpenGLTexture::UInt8, &data[0]);
        m_noiseTextures[i] = tex;
    }
}

void RenderContextOld::checkCreateBlankFbo()
{
    if(!m_blankFbo) {
        m_blankFbo = std::make_shared<QOpenGLFramebufferObject>(QSize(1,1));
        glBindTexture(GL_TEXTURE_2D, m_blankFbo->texture());
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glClear(GL_COLOR_BUFFER_BIT);
        glBindTexture(GL_TEXTURE_2D, 0);
    }
}

void RenderContextOld::render() {
    qint64 framePeriod = elapsed_timer.nsecsElapsed();
    elapsed_timer.restart();
    {
        QMutexLocker locker(&m_contextLock);

        makeCurrent();
        checkLoadShaders();
        checkCreateNoise();
        checkCreateBlankFbo();

        for(auto n : topoSort()) {
            n->render();
        }
    }
    emit renderingFinished();
    //qint64 renderingPeriod = elapsed_timer.nsecsElapsed();
    m_framePeriodLPF += FPS_ALPHA * (framePeriod - m_framePeriodLPF);
    m_rendering.release();
    emit fpsChanged(fps());
}

qreal RenderContextOld::fps() {
    return 1000000000/m_framePeriodLPF;
}

void RenderContextOld::makeCurrent() {
    context->makeCurrent(surface);
}

void RenderContextOld::flush() {
    context->functions()->glFinish();
}

void RenderContextOld::addVideoNodeOld(VideoNodeOld* n) {
    // It is less clear to me if taking the context lock
    // is necessary here
    QMutexLocker locker(&m_contextLock);
    m_videoNodes.insert(n);
}

void RenderContextOld::removeVideoNodeOld(VideoNodeOld* n) {
    // Take the context lock to avoid deleting anything
    // required for the current render
    QMutexLocker locker(&m_contextLock);
    m_videoNodes.remove(n);
}

void RenderContextOld::addSyncSource(QObject *source) {
    m_syncSources.append(source);
    if(m_syncSources.last() != m_currentSyncSource) {
        if(m_currentSyncSource != NULL) disconnect(m_currentSyncSource, SIGNAL(frameSwapped()), this, SLOT(update()));
        m_currentSyncSource = m_syncSources.last();
        connect(m_currentSyncSource, SIGNAL(frameSwapped()), this, SLOT(update()), Qt::DirectConnection);
    }
}

void RenderContextOld::removeSyncSource(QObject *source) {
    m_syncSources.removeOne(source);
    if(m_syncSources.isEmpty()) {
        disconnect(m_currentSyncSource, SIGNAL(frameSwapped()), this, SLOT(update()));
        m_currentSyncSource = NULL;
        qDebug() << "Removed last sync source, video output will stop now";
    }
    else if(m_syncSources.last() != m_currentSyncSource) {
        disconnect(m_currentSyncSource, SIGNAL(frameSwapped()), this, SLOT(update()));
        m_currentSyncSource = m_syncSources.last();
        connect(m_currentSyncSource, SIGNAL(frameSwapped()), this, SLOT(update()), Qt::DirectConnection);
    }
}

QList<VideoNodeOld*> RenderContextOld::topoSort()
{
    // Fuck this

    auto sortedNodes = QList<VideoNodeOld*>{};
    auto fwdEdges = std::map<VideoNodeOld*, QSet<VideoNodeOld*> >{};
    auto revEdges = std::map<VideoNodeOld*, int>{};

    auto startNodes = std::deque<VideoNodeOld*>{};
    auto videoNodes = m_videoNodes;
    for(auto && n: videoNodes) {
        auto deps = n->dependencies();
        revEdges.emplace(n, deps.size());
        if(deps.empty())
            startNodes.push_back(n);
        else for(auto c : deps)
            fwdEdges[c].insert(n);

    }
    while(!startNodes.empty()) {
        auto n = startNodes.back();
        startNodes.pop_back();
        sortedNodes.append(n);
        auto fwd_it = fwdEdges.find(n);
        if(fwd_it != fwdEdges.end()) {
            for(auto c: fwd_it->second) {
                auto &refcnt = revEdges[c];
                if(!--refcnt)
                    startNodes.push_back(c);
            }
            fwdEdges.erase(fwd_it);
        }
    }
    if(!fwdEdges.empty()) {
        qDebug() << "Cycle detected!";
        return {};
    }
    return sortedNodes;
}

int RenderContextOld::outputCount() {
    return m_outputCount;
}


int RenderContextOld::previewFboIndex() {
    return 0;
}

int RenderContextOld::outputFboIndex() {
    return 1;
}

QSize RenderContextOld::fboSize(int i) {
    if(i == previewFboIndex())
        return uiSettings->previewSize();
    if(i == outputFboIndex())
        return uiSettings->outputSize();
    return QSize(0, 0);
}