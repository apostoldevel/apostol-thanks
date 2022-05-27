var appConfig = {
  defaultLanguage: "ru",

  creditsText: "THNX - Donate system © 2022",
  creditsShortText: "THNX",

  signIn: "/signin",
  signUp: "/signup",

  confAuthorize: true,
  confCrm: false,
  confOcpp: false,
  confAdmin: true,

  ocppApiDomain: "http://localhost:8080",
  ocppApiPath: "/api/v1",
  ocppApiClienId: "web-donate-system.ru",

  apiTokenUrl: "/oauth2/token",
  apiDomain: "http://localhost:8080",
  wsDomain: "ws://localhost:8080",
  apiPath: "/api/v1",
  apiClientId: "web-donate-system.ru",

  adminReferences: {
    model: {
      extraFields: {
        vendor: {
          type: "reference",
          path: "/vendor/list",
          required: true,
        },
      },
    },
    vendor: {},
    network: {},
  },

  maxFileSize: 512000,
};
