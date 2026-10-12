#include "VideoSettingsTest.h"

#include <QtCore/QScopeGuard>

#include "SettingsManager.h"
#include "VideoSettings.h"

void VideoSettingsTest::_video2SourceChoices()
{
    VideoSettings* const settings = SettingsManager::instance()->videoSettings();
    QVERIFY(settings);

    Fact* const video2Source = settings->video2Source();
    QVERIFY(video2Source);

    const QVariantList values = video2Source->enumValues();
    QVERIFY(values.contains(QString(VideoSettings::videoDisabled)));
    QVERIFY(values.contains(QString(VideoSettings::videoSourceRTSP)));
    QVERIFY(values.contains(QString(VideoSettings::videoSourceUDPH264)));
    QVERIFY(values.contains(QString(VideoSettings::videoSourceTCP)));
    QCOMPARE(video2Source->enumStrings().count(), values.count());
}

void VideoSettingsTest::_video2ConfiguredIndependently()
{
    VideoSettings* const settings = SettingsManager::instance()->videoSettings();
    QVERIFY(settings);

    Fact* const video1Source = settings->videoSource();
    Fact* const video2Source = settings->video2Source();
    Fact* const video2RtspUrl = settings->video2RtspUrl();
    QVERIFY(video1Source);
    QVERIFY(video2Source);
    QVERIFY(video2RtspUrl);

    const QVariant savedVideo1Source = video1Source->rawValue();
    const QVariant savedVideo2Source = video2Source->rawValue();
    const QVariant savedVideo2RtspUrl = video2RtspUrl->rawValue();
    const auto restore = qScopeGuard([=] {
        video1Source->setRawValue(savedVideo1Source);
        video2Source->setRawValue(savedVideo2Source);
        video2RtspUrl->setRawValue(savedVideo2RtspUrl);
    });

    video1Source->setRawValue(QString(VideoSettings::videoDisabled));
    video2Source->setRawValue(QString(VideoSettings::videoDisabled));
    QVERIFY(!settings->video2StreamConfigured());

    video2RtspUrl->setRawValue(QStringLiteral("rtsp://127.0.0.1:8554/second"));
    video2Source->setRawValue(QString(VideoSettings::videoSourceRTSP));
    QCOMPARE(video2Source->rawValue().toString(), QString(VideoSettings::videoSourceRTSP));
    QVERIFY(settings->video2StreamConfigured());
    QCOMPARE(video1Source->rawValue().toString(), QString(VideoSettings::videoDisabled));
}

UT_REGISTER_TEST(VideoSettingsTest, TestLabel::Unit)
