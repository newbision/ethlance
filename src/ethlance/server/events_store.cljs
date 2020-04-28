(ns ethlance.server.events-store
  (:require [mount.core :as mount :refer [defstate]]
            [taoensso.timbre :as log]
            [cljs.nodejs :as nodejs]
            [district.server.config :refer [config]]
            [cljs.reader :refer [read-string]]))

(declare start stop)

(def fs (nodejs/require "fs"))

(defstate ^{:on-reload :noop} events-store
  :start (start)
  :stop (stop))

(def event-type {:ethereum-log 0
                 :graphql-mutation 1})

(def event-type-key (->> event-type
                         (map (fn [[k v]] [v k]))
                         (into {})))

(defn save-log-event [event-t data]
  (let [str-ev (pr-str {:event/timestamp (.getTime (js/Date.))
                        :event/type (event-type event-t)
                        :event/body (pr-str data)})]
    (.write (:events-store-file-stream @events-store)
            (str str-ev "\n"))))

(defn save-ethereum-log-event [event-body-map]
  (save-log-event :ethereum-log event-body-map))

(defn save-graphql-mutation-event [mutation-body-map]
  (save-log-event :graphql-mutation mutation-body-map))

(defn load-replay-system-events []
  (let [store-file (-> @config :event-store :store-file)
        file-content (.readFileSync fs store-file #js {:encoding "utf8"
                                                       :flag "r"})
        file-str-edn (str "[" file-content "]")]
    (read-string file-str-edn)))

(defn start []
  (log/debug "Starting Events store...")
  (let [file-name (-> @config :event-store :store-file)]
    {:events-store-file-stream (.createWriteStream fx file-name #js {:flags "a"})})
  )

(defn stop []
  (log/debug "Stopping Events store...")

  )
