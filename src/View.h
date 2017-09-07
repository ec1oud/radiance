#pragma once
#include <QQuickItem>
#include "Model.h"

struct Child {
    VideoNode *videoNode;
    QSharedPointer<QQuickItem> item;
    QVector<int> inputHeights;
};

class View : public QQuickItem {
    Q_OBJECT
    Q_PROPERTY(Model *model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QVariantMap delegates READ qml_delegates WRITE qml_setDelegates NOTIFY qml_delegatesChanged)

public:
    View();
    ~View() override;

    Model *model();
    void setModel(Model *model);
    QMap<QString, QString> delegates();
    void setDelegates(QMap<QString, QString> delegates);
    QVariantMap qml_delegates();
    void qml_setDelegates(QVariantMap delegates);

public slots:
    void onGraphChanged();

    // Selection
    void select(QVariantList tiles);
    void addToSelection(QVariantList tiles);
    void removeFromSelection(QVariantList tiles);
    void toggleSelection(QVariantList tiles);
    void ensureSelected(QQuickItem *tile);
    QVariantList selection();

    // Finds the connected components of the selection
    // Each connected component will have zero or more inputs and one output
    // (though possibly multiple output edges.)
    // This is useful because it may be treated as a single tile.
    // Returns a list of objects with three keys:
    // * tiles = A QVariantList of tiles contained within the connected component
    // * vertices = A QVariantList of vertices (VideoNodes) contained within the connected component
    // * edges = A QVariantList of edges contained within the connected component
    // * inputEdges = A QVariantList of input edges to the connected component (ordered)
    // * outputEdges = A QVariantList of output edges from the connected component (unordered)
    // * inputPorts = A QVariantList of QVariantMaps of {vertex, input}
    // * outputNode = The output VideoNode
    QVariantList selectedConnectedComponents();

protected:
    Model *m_model;
    QMap<QString, QString> m_delegates;
    QList<Child> m_children;
    QList<QSharedPointer<QQuickItem>> m_dropAreas;
    void rebuild();
    Child newChild(VideoNode *videoNode);
    QSet<QQuickItem *> m_selection;
    void selectionChanged();

private:
    QSharedPointer<QQuickItem> createDropArea();

signals:
    void modelChanged(Model *model);
    void qml_delegatesChanged(QVariantMap delegates);
    void delegatesChanged(QMap<QString, QString> delegates);
};