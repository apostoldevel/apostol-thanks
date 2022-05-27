--------------------------------------------------------------------------------
-- CUSTOMER AUTH ---------------------------------------------------------------
--------------------------------------------------------------------------------

SELECT AddAlgorithm('HS256', 'SHA256');
SELECT AddAlgorithm('HS384', 'SHA384');
SELECT AddAlgorithm('HS512', 'SHA512');

SELECT AddProvider('I', 'system', 'OAuth 2.0 system provider');
SELECT AddProvider('I', 'default', 'OAuth 2.0 default provider');

SELECT AddProvider('E', 'google', 'Google');
--SELECT AddProvider('E', 'firebase', 'Google Firebase');

SELECT AddApplication('S', 'system', 'Current system');
SELECT AddApplication('S', 'service', 'Service application');
SELECT AddApplication('W', 'web', 'Server-site Web application');
SELECT AddApplication('N', 'android', 'Android mobile application');
SELECT AddApplication('N', 'ios', 'iOS mobile application');

SELECT AddIssuer(GetProvider('default'), 'accounts.donate-system.ru', 'THNX - Donate system');

SELECT AddIssuer(GetProvider('google'), 'accounts.google.com', 'Google account');
SELECT AddIssuer(GetProvider('google'), 'https://accounts.google.com', 'Google account');

SELECT CreateAudience(GetProvider('system'), GetApplication('system'), GetAlgorithm('HS512'), current_database(), GetSecretKey(), 'OAuth 2.0 Client Id for current data base.');

SELECT CreateAudience(GetProvider('default'), GetApplication('service'), GetAlgorithm('HS512'), 'service-donate-system.ru', 'JLFNkBWWzehemKc8XS4xq0Je', 'OAuth 2.0 Client Id for Service Accounts.');
SELECT CreateAudience(GetProvider('default'), GetApplication('web'), GetAlgorithm('HS256'), 'web-donate-system.ru', 'lhI5KU1UMauAca648pOXVvUa', 'OAuth 2.0 Client Id for Server-site and JavaScript Web applications.');
SELECT CreateAudience(GetProvider('default'), GetApplication('android'), GetAlgorithm('HS256'), 'android-donate-system.ru', 'LEhl73UZ12Q24OJYRoTOFGcN', 'OAuth 2.0 Client Id for Android mobile applications.');
SELECT CreateAudience(GetProvider('default'), GetApplication('ios'), GetAlgorithm('HS256'), 'ios-donate-system.ru', 'CHDfZA1bJ4hllfR01tpiUfpt', 'OAuth 2.0 Client Id for iOS mobile applications.');

--SELECT CreateAudience(GetProvider('google'), GetApplication('web'), GetAlgorithm('HS256'), '.apps.googleusercontent.com', '', 'Google Client Id for donate-system.ru');

SELECT AddMemberToGroup(CreateUser(code, secret, 'OAuth 2.0 Client Id', null,null, name, false, true), GetGroup('system')) FROM oauth2.audience;
