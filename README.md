# Thanks

**Thanks** - Система донатов для авторов.

ОПИСАНИЕ
-
**Thanks** - это серверная часть [пет проекта](https://github.com/alexey-goloburdin/thanks) [Алексея Голобурдина](https://www.youtube.com/c/%D0%94%D0%B8%D0%B4%D0%B6%D0%B8%D1%82%D0%B0%D0%BB%D0%B8%D0%B7%D0%B8%D1%80%D1%83%D0%B9).

Реализовано на базе [Апостол CRM](https://github.com/apostoldevel/apostol-crm).

API
-

[REST API](https://github.com/apostoldevel/module-AppServer#rest-api)

[WebSocket API](https://github.com/apostoldevel/module-WebSocketAPI#websocket-api)

СБОРКА И УСТАНОВКА
-

Для сборки проекта Вам потребуется:

1. Компилятор C++;
1. [CMake](https://cmake.org) или интегрированная среда разработки (IDE) с поддержкой [CMake](https://cmake.org);
1. Библиотека [libpq-dev](https://www.postgresql.org/download) (libraries and headers for C language frontend development);
1. Библиотека [postgresql-server-dev-all](https://www.postgresql.org/download) (libraries and headers for C language backend development).

### Linux (Debian/Ubuntu)

Для того чтобы установить компилятор C++ и необходимые библиотеки на Ubuntu выполните:
~~~
$ sudo apt-get install build-essential libssl-dev libcurl4-openssl-dev make cmake gcc g++
~~~

###### Подробное описание установки C++, CMake, IDE и иных компонентов необходимых для сборки проекта не входит в данное руководство.

#### PostgreSQL

Для того чтобы установить PostgreSQL воспользуйтесь инструкцией по [этой](https://www.postgresql.org/download/) ссылке.

#### База данных

Для того чтобы установить базу данных необходимо выполнить:

1. Прописать наименование базы данных в файле db/sql/sets.conf (по умолчанию: `thanks`)
1. Прописать пароли для пользователей СУБД [libpq-pgpass](https://postgrespro.ru/docs/postgrespro/14/libpq-pgpass):
   ~~~
   $ sudo -iu postgres -H vim .pgpass
   ~~~
   ~~~
   *:*:*:kernel:kernel
   *:*:*:admin:admin
   *:*:*:daemon:daemon
   ~~~
1. Указать в файле настроек /etc/postgresql/{version}/main/postgresql.conf:
   Пути поиска схемы kernel:
   ~~~
   search_path = '"$user", kernel, public'	# schema names
   ~~~
1. Указать в файле настроек /etc/postgresql/{version}/main/pg_hba.conf:
   ~~~
   # TYPE  DATABASE        USER            ADDRESS                 METHOD
   local	all		kernel					md5
   local	all		admin					md5
   local	all		daemon					md5
    
   host	all		kernel		127.0.0.1/32		md5
   host	all		admin		127.0.0.1/32		md5
   host	all		daemon		127.0.0.1/32		md5   
   ~~~
1. Выполнить:
   ~~~
   $ cd db/
   $ ./install.sh --make
   ~~~

###### Параметр `--make` необходим для установки базы данных в первый раз. Далее установочный скрипт можно запускать или без параметров или с параметром `--install`.

##### Для сборки **Thanks**, с помощью Git выполните:
~~~
$ git clone https://github.com/apostoldevel/apostol-thanks.git
~~~
Далее:
1. Настроить `CMakeLists.txt` (по необходимости);
1. Собрать и скомпилировать (см. ниже).

##### Для того чтобы установить **Thanks** (без Git) необходимо:

1. Скачать **Thanks** по [ссылке](https://github.com/apostoldevel/apostol-thanks/archive/master.zip);
1. Распаковать;
1. Настроить `CMakeLists.txt` (по необходимости);
1. Собрать и скомпилировать (см. ниже).

###### Сборка:
~~~
$ cd thanks
$ ./configure
~~~

###### Компиляция и установка:
~~~
$ cd cmake-build-release
$ make
$ sudo make install
~~~

По умолчанию бинарный файл `thanks` будет установлен в:
~~~
/usr/sbin
~~~

Файл конфигурации и необходимые для работы файлы, в зависимости от варианта установки, будут расположены в: 
~~~
/etc/thanks
или
~/thanks
~~~

ЗАПУСК 
-
###### Если `INSTALL_AS_ROOT` установлено в `ON`.

**`thanks`** - это системная служба (демон) Linux. 
Для управления **`thanks`** используйте стандартные команды управления службами.

Для запуска `thanks` выполните:
~~~
$ sudo service thanks start
~~~

Для проверки статуса выполните:
~~~
$ sudo service thanks status
~~~

Результат должен быть **примерно** таким:
~~~
● thanks.service - Thanks (Donate system)
   Loaded: loaded (/usr/lib/systemd/system/thanks.service; enabled; vendor preset: disabled)
   Active: active (running) since Tue 2021-12-28 14:24:04 UTC; 1 weeks 0 days ago
  Process: 878560 ExecReload=/bin/kill -s HUP $MAINPID (code=exited, status=0/SUCCESS)
  Process: 938206 ExecStart=/usr/sbin/thanks (code=exited, status=0/SUCCESS)
  Process: 938204 ExecStartPre=/usr/sbin/thanks -t (code=exited, status=0/SUCCESS)
  Process: 938202 ExecStartPre=/usr/bin/rm -f /run/thanks.pid (code=exited, status=0/SUCCESS)
 Main PID: 938207 (thanks)
    Tasks: 4 (limit: 49484)
   Memory: 20.1M
   CGroup: /system.slice/thanks.service
           ├─938207 thanks: master process /usr/sbin/thanks
           ├─938208 thanks: worker process ("web socket api", "application server", "authorization server", "web server")
           ├─938209 thanks: message server
           └─938210 thanks: job scheduler
~~~

### **Управление**.

Управлять **`thanks`** можно с помощью сигналов.
Номер главного процесса по умолчанию записывается в файл `/run/thanks.pid`. 
Изменить имя этого файла можно при конфигурации сборки или же в `thanks.conf` секция `[daemon]` ключ `pid`. 

Главный процесс поддерживает следующие сигналы:

|Сигнал   |Действие          |
|---------|------------------|
|TERM, INT|быстрое завершение|
|QUIT     |плавное завершение|
|HUP	  |изменение конфигурации, запуск новых рабочих процессов с новой конфигурацией, плавное завершение старых рабочих процессов|
|WINCH    |плавное завершение рабочих процессов|	

Управлять рабочими процессами по отдельности не нужно. Тем не менее, они тоже поддерживают некоторые сигналы:

|Сигнал   |Действие          |
|---------|------------------|
|TERM, INT|быстрое завершение|
|QUIT	  |плавное завершение|
