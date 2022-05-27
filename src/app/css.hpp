/*++

Program name:

  css

Module Name:

  css.hpp

Notices:

  OCPP Central System Service

Author:

  Copyright (c) Prepodobny Alen

  mailto: alienufo@inbox.ru
  mailto: ufocomp@gmail.com

--*/

#ifndef APOSTOL_CSS_HPP
#define APOSTOL_CSS_HPP
//----------------------------------------------------------------------------------------------------------------------

#include "../../version.h"
//----------------------------------------------------------------------------------------------------------------------

#define APP_VERSION      AUTO_VERSION
#define APP_VER          APP_NAME "/" APP_VERSION
//----------------------------------------------------------------------------------------------------------------------

#include "Header.hpp"
//----------------------------------------------------------------------------------------------------------------------

extern "C++" {

namespace Apostol {

    namespace CSS {

        class CCSS: public CApplication {
        protected:

            void ParseCmdLine() override;
            void ShowVersionInfo() override;

            void StartProcess() override;
            void CreateCustomProcesses() override;

        public:

            CCSS(int argc, char *const *argv): CApplication(argc, argv) {

            };

            ~CCSS() override = default;

            static class CCSS *Create(int argc, char *const *argv) {
                return new CCSS(argc, argv);
            };

            inline void Destroy() override { delete this; };

            void Run() override;

        };
    }
}

using namespace Apostol::CSS;
}

#endif //APOSTOL_CSS_HPP

