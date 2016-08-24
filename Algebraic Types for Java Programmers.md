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

    public static A unwrap(Sum<A,A> a) {
      return a.which == Side.Left ? a.left : a.right;
    }
  }
```
The most important part of Sum is that any instance of Sum only has one of its
two possible 'spaces' filled. Thus Sum represents the type that could be either
A or B, but not both at the same time. This is in contrast to Product which must
have both spaces filled at construction. Also notice that Sum has two was to
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
natural number. Stream is some item and a Stream. Since there is no null, there
is always another stream to project another item and stream 
