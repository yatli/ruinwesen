(in-package :template.tags)

(cl-interpol:enable-interpol-syntax)

(define-bknr-tag head (&key title)
  (html (:head
         (:title (:princ-safe title))
         ((:link :rel "shortcut icon" :href "static/images/favicon.ico" :type "image/x-icon"))
         ((:link :type "text/css" :rel "stylesheet" :media "all" :href "static/css/reset.css"))
         ((:link :type "text/css" :rel "stylesheet" :media "all" :href "static/css/style.css")))))

(define-bknr-tag header ()
  (html ((:div :id "head")
         (:h1 (:span) "Odendahl Systemprogrammierung")
         ((:ul :id "nav")
          (dolist (elt '(("About" . "/index")
                         ("Services" . "/services")
                         ("Projects" . ("/projects" "/project"))
                         ("Blog" . "/blog")
                         ("Contact" . "/contact")))
            (cond
              ((if (listp (cdr elt))
                   (member (hunchentoot:script-name*) (cdr elt) :test #'string=)
                   (string= (hunchentoot:script-name*) (cdr elt)))
               (html ((:li :class "selected") (:princ-safe (car elt)))))
              (t
               (html (:li ((:a :href (if (listp (cdr elt))
                                         (first (cdr elt))
                                         (cdr elt)))
                           (:princ-safe (car elt))))))))))))

(define-bknr-tag project-box (&key id)
  (let ((project (if id
                     (find-store-object id :class 'template::portfolio-project)
                     (random-elts (store-objects-with-class 'template::portfolio-project) 1))))
    (html ((:li :class "projectbox")
           ((:a :href (format nil "/project?id=~a" (store-object-id project))
                :alt (template::portfolio-project-title project))
            ((:img :src (format nil "/image/~a" (store-object-id (template::portfolio-project-box-image project)))
                   :alt (template::portfolio-project-title project)))
            ((:p :class "legend")
             (:princ-safe (template::portfolio-project-title project))))))))

(define-bknr-tag project-list (&key count tag random)
  (setf count (when count (parse-integer count))
        tag (when tag (make-keyword-from-string tag)))
  (let ((projects
         (sort (copy-tree (if tag
                              (template::get-projects-with-tag tag)
                              (store-objects-with-class 'template::portfolio-project)))
               #'> :key #'template::portfolio-project-time)))
    (when random
      (setf projects (randomize-list projects)))
    (when count
      (setf projects (subseq projects 0 (min (length projects) count))))
    (html ((:ul :class "projectlist")
           (dolist (project projects)
             (project-box :id (store-object-id project)))))))

(define-bknr-tag footer ()
  (html ((:div :id "footer")
         ((:div :id "twitterbox")
          ((:img :src "static/images/twitter-bird.png" :alt "Twitter bird"))
          (:p "Follow me on " (:br) ((:a :href "http://twitter.com/wesen" :alt "wesen on twitter") "twitter") "!"))
         ((:div :id "bookbox")
          ((:img :src "static/images/arduino-book.png" :alt "Arduino Book"))
          (:p "Buy our book on " ((:a :href "http://www.amazon.de/Arduino-Physical-Computing-Designer-oreillys/dp/3897218933" :alt "Arduino Buch auf Amazon") "amazon") "!"))
         ((:p :id "copyright") "(c) 2010 Manuel Odendahl" (:br)
          ((:a :href "/legal" :alt "Legal information") "legal / impressum")))))

(define-bknr-tag category-list ()
  (html ((:ul :id "categories")
         (dolist (category (template::project-tag-sorted-list))
           (let ((name (string-downcase (car category))))
             (html (:li ((:span :class "category")
                         ((:a :href (format nil "/projects?tag=~a" name)
                              :alt (format nil "~a projects" name))
                          (:princ-safe name)))
                        ((:span :class "category-count")
                         (:princ-safe (cdr category))))))))))

;; handle the contact form

(defvar *contact-form-errors* nil)

(define-bknr-tag contact-form ()
  (with-query-params (name email website message submit)
    (if submit
        (if (or (null name) (null email) (null message))
            (let ((*contact-form-errors* "Please fill out the required fields!"))
              (emit-tag-child 0))
            (progn
              (cl-smtp:send-email "localhost" email "manuel"
                                  (format nil "Portfolio: Message from ~A <~A> (~A)" name email website)
                                  message)
              (html ((:div :class "message") 
                     (:p "Thank you for your message! I will try to respond as fast as possible.")))))
        (emit-tag-child 0))))

(define-bknr-tag contact-form-errors ()
  (when *contact-form-errors*
    (html ((:p :class "error") (:princ-safe *contact-form-errors*)))))
  
    

;; login and admin page tags
(define-bknr-tag login-page ()
  (if (and (hunchentoot:session-value :login-redirect-uri)
           (not (bknr.user:anonymous-p (bknr-session-user))))
      (redirect (puri:render-uri (hunchentoot:session-value :login-redirect-uri) nil))
      (emit-tag-children)))


(define-bknr-tag admin-page ()
  (if (bknr.web::admin-p (bknr-session-user))
      (emit-tag-children)
      (progn
        (setf (hunchentoot:session-value :login-redirect-uri)
              (parse-uri (hunchentoot:script-name*)))
        (redirect "/login"))))