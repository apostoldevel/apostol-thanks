/*++

Program name:

  thnx

Module Name:

  thnx.hpp

Notices:

  THNX - Donate System

Author:

  Copyright (c) Prepodobny Alen

  mailto: alienufo@inbox.ru
  mailto: ufocomp@gmail.com

--*/

#ifndef APOSTOL_THNX_HPP
#define APOSTOL_THNX_HPP
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

    namespace THNX {

        class CTHNX: public CApplication {
        protected:

            void ParseCmdLine() override;
            void ShowVersionInfo() override;

            void StartProcess() override;
            void CreateCustomProcesses() override;

        public:

            CTHNX(int argc, char *const *argv): CApplication(argc, argv) {

            };

            ~CTHNX() override = default;

            static class CTHNX *Create(int argc, char *const *argv) {
                return new CTHNX(argc, argv);
            };

            inline void Destroy() override { delete this; };

            void Run() override;

        };
    }
}

using namespace Apostol::THNX;
}

#endif //APOSTOL_THNX_HPP

