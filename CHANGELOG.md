## [1.3.3] - 2017.12.12

* a push message id in push result was unified (single `id` key): a pair of `message_id` and `multicast_id` for FCM, `apns_id` for APNS

## [1.3.2] - 2017.12.11

* apns-id of APNS push message was added into response

## [1.3.1] - 2017.12.04

* Bug with sync push and push_message == nil in callback_fun was fixed

## [1.3.0] - 2017.11.17

* No link b/w consumer & task
* Adjusted timeouts
* Buffer ping

## [1.2.10, 1.2.11, 1.2.12] - 2017.11.14

* Dynamic consumer
* Automatic consumer
* Buffer sync add

## [1.2.8, 1.2.9] - 2017.11.13

* Added APNS sync/async option for a worker (async is faster, sync is more stable)
* Tasks Supervisor: :temporary restart strategy
* bug fixes

## [1.2.6, 1.2.7] - 2017.11.10

* Tasks & their Supervisor improvements

## [1.2.5] - 2017.11.02

* APNS worker's asunc push
* APNS worker ttl

## [1.2.4] - 2017.11.01

* refactored APNS worker check
* APNS push operation async option
* timeouts handling
* some other improvements

## [1.2.3] - 2017.10.31

* checks if APNS worker is alive before push
* checks for opened frames count per connection before push

## [1.2.2] - 2017.10.31

* APNS: worker checks if a connection alive before push
* APNS: tries to redeliver push messages of crashed workers

## [1.2.1] - 2017.10.31

* does not rely on Mix.env (uses Application.get_env(:express, :environment) instead)

## [1.2.0] - 2017.10.30

* added APNS :auth_key as p8 file content in config
* configuration via module

## [1.1.3] - 2017.10.27

* fixed APNS :cert & :key config attributes resolving

## [1.1.2] - 2017.10.27

* got rid enforced_keys from Express.FCM.PushMessage.Notification

## [1.1.1] - 2017.10.26

* Fixed a bug with field names of APNS payload (they should be dasherized).
* Added a validation on APNS payload fields.
* Added `thread_id` field to APNS aps structure

## [1.1.0] - 2017.10.26

* JWT for APNS
* GenStage for load balancing
* Refactored supervision tree

## [1.0.0] - 2017.07.23

the first publication on hex.pm
