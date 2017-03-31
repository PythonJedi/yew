/*
 *  Header file for Yew's Abstract Syntax Tree.
 */

#ifndef YEW_AST_H
#define YEW_AST_H

#include <list>
#include <string>

namespace yew {

    class Atom {
        public:
            static Atom True = Atom("Unit");
            static Atom False = Atom("Void");
            Atom(std::string name) {this->name = name;}
            final std::string name;
    };

    struct Proposition {
        enum {Quantifier, Connective, Atomic} tag;
        union {
            struct {
                enum {Universal, Existential, Inductive, Iterative} type;
                std::list<std::string> vars;
                Proposition body;
            } *quantifier;

            struct {
                enum {Conjunction, Disjunction, Implication, Coimplication} type;
                std::list<Proposition> props;
            } *connective;

            Atom *atom;
        } data;
    };

    struct Sequent {
        Proposition assumption;
        Proposition conclusion;
    };

}

#endif
