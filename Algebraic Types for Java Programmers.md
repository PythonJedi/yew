Algebraic Types are generally the domain of languages like Haskell and OCaml.
However, the core tenants can be applied to less abstract languages such as Java
through a bit of creative thinking and some restriction on what may be allowed.

## Basis of Algebraic Types

Simple algebraic types consist of three 'constructors': Function, Product, and
Sum (or Coproduct). Each of these constructors take two types and return a
different type. Each constructor also has an associated 'map' function that
takes two functions and combines them in a similar way as the types. Let's start
with product, as it is the most straightforward.

### Product
```java
  public class Product<A, B> {
    private A left;
    private B right;

    public static Product(A a, B b) {
      this.left = a;
      this.rght = b;
    }

    public static A projleft(Product<A,B> p) {
      return p.left;
    }

    public static B projright(Product<A,B> p) {
      return p.right;
    }

    public static Function<Product<A,B>,Product<C,D>> map (Function<A,C> f,
                                                           Function<B,D> g) {
      return p -> Product<C,D>(f.call(Product<A,B>.projleft(p)),
                               g.call(Product<A,B>.projright(p)))
    }

    public static Product<A,A> double (A a) {
      return Product<A,A>(a,a);
    }
  }
```
Product is used to have two values or functions attached to one another so that
they may be passed around as a single entity. Notice that there is no way to
modify the values inside a product. This is a feature known as immutability, and
it makes programs a lot simpler to reason about.

The type signature of Product<A,B>.map includes Function as a type constructor.
This is necessary because java doesn't allow functions as direct types. In order
to pass around functions we must encapsulate them in an object. Let us therefore
take a look at Function.

### Function
```java
  public interface Function<A,B> {
    B call(A a);

    static Function<Function<B,C>,Function<A,D>> map (Function<A,B> f,
                                                      Function<C,D> g) {
      return h -> (a -> g.call(h.call(f.call(a))))
    }

    static  Function<A,C> compose (Function<A,B> f, Function<B,C> g) {
      return a -> g.call(f.call(a))
    }
  }
```
Function is a bit special because of java's aforementioned issues with
first-class functions. In order to instantiate a Function, one must create a
class that implements Function. Alternately, one can use a lambda expression.
In fact, lambda expressions and composition are the bread and butter of
functional programming, hence why the definition of Function includes a compose
helper along with the more flexible map. With function defined, all we have left
to consider for basic algebraic data types is the Sum or Coproduct.

### Sum
```java
  public class Sum<A,B> {
    private enum Side {Left, Right}
    private A left;
    private B right;
    private Side which;

    public Sum(A a) {
      this.which = Left;
      this.left = a;
    }

    public Sum(B b) {
      this.which = Right;
      this.right = b;
    }

    public static Function<Sum<A,B>,Sum<C,D>> map (Function<A,C> f,
                                                   Function<B,D> g) {
      return s -> Sum<C,D>(s.which == Side.Left ? f.call(s.left) :
                                                  g.call(s.right));
    }

    public static A unwrap (Sum<A,A> a) {
      return a.which == Side.Left ? a.left : a.right;
    }
  }
```
The most important part of Sum is that any instance of Sum only has one of its
two possible 'spaces' filled. Thus Sum represents the type that could be either
A or B, but not both at the same time. This is in contrast to Product which must
have both spaces filled at construction. Also notice that Sum has two ways to
wrap a value as a Sum, while Product has two ways to unwrap a product into a
value. This kind of relationship where two things are related with components
reversed is known in mathematics as duality, and we'll be exploring it for the
entirety of this document.

## Variable Size and Infinitely Large Types

The algebraic type constructors handled so far can create structures of great
flexibility. We can turn functions of one type into functions of other types via
composition/function.map, describe multiple types in a group via product, and
describe the possibility of different types via sum. One of the things we are
not able to do with these three constructors is to create types of arbitrary
length. As programmers need to be able to describe data of indeterminate length,
algebraic types must be extended to allow for such types.

### Fixed Points

We handle variable sized types in traditional type theory via what are known as
Fixed Points. If we have some algebraic type expression F with an undefined term
X in it, we can define the fixed point of F with respect to X. This is the type
where X is replaced by F, introducing more Xs that can then be replaced by F, as
many times as is needed. When this fixed point is desired to be finite, it is
called the Least Fixed Point, when the fixed point can be infinite, it is called
the Greatest Fixed Point.

### Java Application

So how do Fixed Points show up in Java? They can be encoded via using the type's
name in its definition, like this implementation of binary trees.

```java
  public class BinaryTree<E> {
    private E val;
    private BinaryTree<E> left;
    private BinaryTree<E> right;
  }
```

Notice that in this case we can 'cheat' a little bit and not require a 'null'
value because java reference types automatically have the possibility of being
'null.' If we were to instead assume that references are always valid and never
null, we would need a 'null' type. Let us call this type 'Unit' because it only
has one value: null. So we then can refine the above definition in a more
explicit manner.

```java
  public class BinaryTree<E> =
    Sum<Unit,Product<E,Product<BinaryTree<E>,BinaryTree<E>>>>{};
```

This is obviously not valid java. However, it does make sense, in that a binary
tree is either a nothing representing an empty tree, or an E and a pair of
binary tree children. This could be turned into valid java by taking the
definitions of sum and product and creating nested classes to match. However,
once we have fundamental ways to combine types, it makes more sense to define
types like we define variables.

Another issue with the above definition is that it could be infinite, or even
looping in a cyclical reference. It would be nice to specify that any instance
of the type is finite, that some function that combines all the elements of the
tree like sum will finish computing. Java has no way to differentiate between
finite and potentially infinite types, the greatest and least fixed points. Such
a check requires a language on top that handles such logic. We could assume such
terms in an improved java like so.

```java
  public class Natural = LFix<X,Sum<Unit,X>>{};
  public class Stream<E> = GFix<X,Product<E,X>>{};
```

In this case, Natural is either a null (in this case representing 0), or some
nesting of n right constructors of Sum around a null, representing the nth
natural number. Stream is some item and a Stream. Since there is no possibility
of null, there is always another stream to project into another item and stream.
Since this structure is known to be potentially infinite (due to the use of
GFix in its declaration), a compiler can check to make sure functions that
depend on all the items in the structure (like sum and print) are not called on
it. However, there are entire groups of functions that can be evaluated on
infinite structures, creating new infinite structures that can be inspected by
partial evaluation of a print function or other suitable output.

## Quantification

The final major component of functional programming with java is that of
quantification. Quantification deals with the binding of variables (fixed points
also bind variables but only in a recursive manner; quantifiers are much more
flexible.) in expressions to create parameterization and data hiding. To use the
black box analogy that oracle is so fond of, quantifiers create black boxes. In
Universal Quantification, the expression being quantified works with the black
boxes of its parameters, types or functions. Existential quantification is its
dual notion, in that the expression being quantified is a black box to the
outside world. Most programmers of all backgrounds are more familiar with
universal quantification, so we will start with that.

### Universal Quantification of Types

We've actually been using universal type quantification this entire time. Java
calls them 'generics.' When a term in a type expression can be any type, we can
universally quantify on that term and create a type 'constructor' that produces
a new type when the type parameter is replaced with an actual type. Doing this
recursively yields the fixed points, as previously noted. However, when we can
quantify on any type, we can do all sorts of neat things.

```java
  public class Maybe<A>
    extends Sum<Unit,A>
    implements Functor, Applicative, Monad{

    public static Maybe<B> map (Function<A,B> f, Maybe<A> m) =
      Sum<Unit,A>.map(Unit::identity, f);

    public static Maybe<B> map (Maybe<Function<A,B>> mf, Maybe<A> m) =
      Sum<Unit,Function<A,B>>.map(Unit::identity, f -> Maybe<A>.map(f,m));

    public Maybe<A> pure (A a) = Sum<Unit,A>::new;

    public static Maybe<B> bind (Function<A,Maybe<B>> f, Mabye<A> m) {
      return  m.which == Left ? Maybe<A>(Unit.none) : f(m);
    }
  }
```

Those of you that know Haskell, take a close look. That is a full definition
of a proper functional Maybe type in (nearly) correct Java. For everyone else,
take a bit of time to think through the possibilities of the above type. The
two map instances allow a function to be applied to the value 'inside' the maybe
if there is a value, otherwise passing the nothing along. The second map allows
for the function to possibly not exist as well (maybe due to an issue loading a
class). The pure is just an alias for the A constructor of the underlying sum
type. Bind allows for a function that produces a maybe (a computation that may
fail) to be applied to a value that may not exist, producing another value that
may not exist. If we had just used map, we would have ended up with a nested
Maybe, which is a bit of a pain to work with. One really neat thing is that we
can define the same four functions for List, Tree, and many other quantified
types. Further additions to this document may dive deeper into the implications
of the Functor, Applicative, and Monad.

Since generics have made the idea of parameterized types relatively common in
the Java world, there is not much else to cover for types. For functions,
universal quantification is a lambda expression. "for all x, (some expression
involving x)" is simply another way of stating a function or lambda.

### Existential Quantification

Existential quantification is a little bit more difficult, and is not nearly as
well known in the functional world. It is dual to universal quantification, as
stated before. For types, existential quantification means that some type of
arbitrary name exists, but that any function using a term of an existential type
cannot make any assumptions about what type it is. Existentials are usually
applied to products, so that multiple related terms can be combined together and
applied to one another. In java, this can be accomplished by using interfaces,
as a function using a term 'masked' as an interface can only assume the
functions defined by the interface exist. To 'instantiate' the existential type,
a class must be defined that implements the interface. A more flexible language
would allow any combination of functions and a type to be thrown together as an
instance of the existential type, but anonymous classes do okay.

##
