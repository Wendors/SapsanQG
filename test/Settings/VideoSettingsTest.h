#pragma once

#include "UnitTest.h"

class VideoSettingsTest : public UnitTest
{
    Q_OBJECT

private slots:
    void _video2SourceChoices();
    void _video2ConfiguredIndependently();
};
