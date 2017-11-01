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
