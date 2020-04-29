(in-package :common-lisp-user)
(defpackage xmls-test
  (:use :common-lisp :fiveam :xmls)
  )

(in-package :xmls-test)

(def-suite xmls-test)

(in-suite xmls-test)

(test check-cdata-backtrack
  (is (equalp (make-node :name "name" :children (list "x]"))
              (parse "<name><![CDATA[x]]]></name>"))))

(test bigger-check-cdata-backtrack
  (is (equalp (make-node :name "description"
                         :children
                         (list 
 "Link to Catalog In this sequel to 2010's surprise hit, Greg Heffley, the kid who made \"wimpy\" cool is back in an all-new family comedy based on the best-selling follow-up novel by Jeff Kinney. (Kinney's Wimpy Kid\" series has thus far sold 42 million books.) As he begins seventh grade, Greg and his older brother [...]"))
              (parse "<description><![CDATA[Link to Catalog In this sequel to 2010's surprise hit, Greg Heffley, the kid who made \"wimpy\" cool is back in an all-new family comedy based on the best-selling follow-up novel by Jeff Kinney. (Kinney's Wimpy Kid\" series has thus far sold 42 million books.) As he begins seventh grade, Greg and his older brother [...]]]></description>"))))

(test simple-nodelist-translator
  (is (equalp (nodelist->node (list "description" nil
 "Link to Catalog In this sequel to 2010's surprise hit, Greg Heffley, the kid who made \"wimpy\" cool is back in an all-new family comedy based on the best-selling follow-up novel by Jeff Kinney. (Kinney's Wimpy Kid\" series has thus far sold 42 million books.) As he begins seventh grade, Greg and his older brother [...]"))
              (parse "<description><![CDATA[Link to Catalog In this sequel to 2010's surprise hit, Greg Heffley, the kid who made \"wimpy\" cool is back in an all-new family comedy based on the best-selling follow-up novel by Jeff Kinney. (Kinney's Wimpy Kid\" series has thus far sold 42 million books.) As he begins seventh grade, Greg and his older brother [...]]]></description>"))))

(def-fixture parsed-greeting ()
  (let ((node
          (with-open-file (str (asdf:system-relative-pathname "xmls" "tests/beep/greeting1.xml")
                               :direction :input)
            (parse str))))
    (&body)))

(test check-accessors
  (with-fixture parsed-greeting ()
    (is (equal "greeting" (node-name node)))
    (is (= 3 (length (node-children node))))
    (is (null (node-attrs node)))
    (is (equal (list "profile" "profile" "profile")
               (mapcar #'node-name (node-children node))))))

(test check-xmlrep-accessors
  (with-fixture parsed-greeting ()
    (is (equal "greeting" (xmlrep-tag node)))
    (is (= 3 (length (xmlrep-children node))))
    (is (null (xmlrep-attribs node)))
    (is (equal (list "profile" "profile" "profile")
               (mapcar #'xmlrep-tag (xmlrep-children node))))))

(def-fixture parsed-article ()
  (let ((node
          (with-open-file (str (asdf:system-relative-pathname "xmls" "tests/nxml/genetics-article.xml")
                               :direction :input)
            (xmls:parse-to-list str))))
    (&body)))

(test check-extract-path
  (with-fixture parsed-article ()
    ;; retrieve first of items matching the path
    (let ((result (xmls:extract-path-list '("OAI-PMH" "GetRecord" "record" "metadata" "article"
                                            "back" "ref-list" "ref")
                                          node)))
      (is (= 4 (length result)))
      (is (equalp (nth 0 result)
                  '("ref" . "http://dtd.nlm.nih.gov/2.0/xsd/archivearticle")))
      (is (equalp (nth 1 result)
                  '(("id" "gkt903-B1")))))

    ;; retrieve tag attributes of first item matching the path
    (let ((result (xmls:extract-path-list '("OAI-PMH" "GetRecord" "record" "metadata" "article"
                                            "back" "ref-list" "ref" . *)
                                          node)))
      (is (equalp result
                  '(("id" "gkt903-B1")))))

    ;; retrieve all items enclosed by element matching the path
    (let ((result (xmls:extract-path-list '("OAI-PMH" "GetRecord" "record" "metadata" "article"
                                            "back" "ref-list" *)
                                          node)))
      (is (= 41 (length result)))
      (is (equalp (nth 0 result)
                  '(("title" . "http://dtd.nlm.nih.gov/2.0/xsd/archivearticle") nil "REFERENCES")))
      (is (equalp (nth 1 (nth 1 result))
                  '(("id" "gkt903-B1"))))
      (is (equalp (nth 1 (nth 15 result))
                  '(("id" "gkt903-B15")))))

    ;; select specific item among several with same tag based on tag attributes
    ;; here selecting on "ref" in the path...
    (let ((result (xmls:extract-path-list '("OAI-PMH" "GetRecord" "record" "metadata" "article"
                                            "back" "ref-list" ("ref" ("id" "gkt903-B15")) "element-citation"
                                            "article-title")
                                          node)))
      (is (equalp result
                  '(("article-title" . "http://dtd.nlm.nih.gov/2.0/xsd/archivearticle") NIL
                    "HNS, a nuclearcytoplasmic shuttling sequence in HuR"))))))

(def-fixture parsed-article-struct ()
  (let ((node
          (with-open-file (str (asdf:system-relative-pathname "xmls" "tests/nxml/genetics-article.xml")
                               :direction :input)
            (xmls:parse str))))
    (&body)))

(test check-extract-path-from-structs
  (with-fixture parsed-article-struct ()
    ;; retrieve first of items matching the path
    (let ((result (xmls:extract-path '("OAI-PMH" "GetRecord" "record" "metadata" "article"
                                       "back" "ref-list" "ref")
                                     node)))
      (is (string= (node-name result) "ref"))
      (is (string= (node-ns result) "http://dtd.nlm.nih.gov/2.0/xsd/archivearticle"))
      (is (equalp (node-attrs result) '(("id" "gkt903-B1")))))

    ;; retrieve tag attributes of first item matching the path
    (let ((result (xmls:extract-path '("OAI-PMH" "GetRecord" "record" "metadata" "article"
                                       "back" "ref-list" "ref" . *)
                                     node)))
      (is (equalp result '(("id" "gkt903-B1")))))

    ;; retrieve all items enclosed by element matching the path
    (let ((result (xmls:extract-path '("OAI-PMH" "GetRecord" "record" "metadata" "article"
                                       "back" "ref-list" *)
                                     node)))
      (is (= 41 (length result)))
      (is (equalp (nth 0 result)
                  (make-node :name "title"
                             :ns "http://dtd.nlm.nih.gov/2.0/xsd/archivearticle"
                             :attrs nil
                             :children '("REFERENCES"))))
      (is (equalp (node-attrs (nth 1 result))
                  '(("id" "gkt903-B1"))))
      (is (equalp (node-attrs (nth 15 result))
                  '(("id" "gkt903-B15")))))

    ;; select specific item among several with same tag based on tag attributes
    ;; here selecting on "ref" in the path...
    (let ((result (xmls:extract-path '("OAI-PMH" "GetRecord" "record" "metadata" "article"
                                       "back" "ref-list" ("ref" ("id" "gkt903-B15")) "element-citation"
                                       "article-title")
                                     node)))
      (is (equalp result
                  (make-node :name "article-title"
                             :ns "http://dtd.nlm.nih.gov/2.0/xsd/archivearticle"
                             :attrs NIL
                             :children '("HNS, a nuclearcytoplasmic shuttling sequence in HuR")))))))
