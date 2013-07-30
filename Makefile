## ########################################################################## ##
## Project: GitHub API v3 bindings in OCaml                                   ##
## Author: db0 (db0company@gmail.com, http://db0.fr/)                         ##
## Latest Version on GitHub: https://github.com/db0company/GitHub-API-OCaml   ##
## ########################################################################## ##

NAME		=	github-ocaml.cma

SRC		=	github.ml

SRCI		=	github.mli

SRCDOC		=	$(SRCI) $(SRC)
PACKS		=	curl,yojson

TEST_NAME	=	example
TEST_SRC	=	example.ml

VERSION		=	1.0.0

FLAGS		=	-linkpkg

CMO		=	$(SRC:.ml=.cmo)
CMI		=	$(SRC:.ml=.cmi)

COMPILER	=	ocamlc
DOCCOMPILER	=	ocamldoc
OCAMLFIND	=	ocamlfind
RM		=	rm -f

all		:	
			$(OCAMLFIND) $(COMPILER) -a -o $(NAME) -package $(PACKS) $(SRCI) $(SRC) $(FLAGS)

doc		:	all
			mkdir -p html/
			$(OCAMLFIND) $(DOCCOMPILER) -html -package $(PACKS) $(SRCDOC) -d html/

$(TEST_NAME)	:	all
			$(OCAMLFIND) $(COMPILER) -o $(TEST_NAME) $(NAME) $(TEST_SRC) $(FLAGS)

clean		:
			$(RM) $(CMI) $(CMO) example.cmi

fclean		:	clean
			$(RM) $(NAME)

re		:	fclean all
