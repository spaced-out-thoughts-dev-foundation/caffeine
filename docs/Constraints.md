# Constraints

***

## Constructing a Graph of Constraints

Each service component is a node in the system connected to dependent components via directed edges. Thus, by transitively traversing the edges, it is possible to determine the relationship between two components. From this, we can determine the type of constraint and thus the reliability expectations.

Specifically, we construct a directed graph (due to the nature of systems, we must support cyclical and acylical graphs alike... and thus do not choose a DAG as our data structure).

***

## Constraint Types

### First Order Constraints

When defining a threshold or objective for a service (an SLO), it's necessary to consider the decision space. It is not typically the _full_ range from 0 (no expectaton) to 100 (perfection). Instead, services usually have a minimum and a maximum defined by tertiary elements: SLAs (service level agreements, aka SLOs with contractual penalties on violation, hard dependencies, and general truths). Thus, we can may define a _decision space framework_ a bit like this:

```
SLA < objective < hard_dependencies

wherean objective considers generatl truths
```

Consider a banking service for fetching a user's balance within a web application. It may have an SLA of 99.9% availability, be built with a database promising 99.999% availability, and since it's on the web, come with acceptance for occasionally requiring a refresh when rendering a surprising or unexpected state.

Thus, leveraging our framework, we know we should aim for more than 3 nines, less than 5 nines, and err closer to 3 nines since our users are fairly forgiving: we may land on 99.95%.

These we call first order constraints since, within a graph of _dependencies_, they're directly connected to this service by a a single edge. 

### N-Order Constraints

Most humans can probably reason about first order constraints. N-Order constraints are more challenging due to the way complex distributed system components interact and webs within a dependency graph. Just like first order constraints, here we seek to provide service owners with restricted decision spaces from which to iterate on for their SLOs. We forsee n-order constraint calculations to, at times, yield surprising results; i.e. decisions spaces well below the service owner's expectations, or, even worse, below their user's expectations. However, while unsatisfactory, this, in itself is an exceptionally useful result as it means the service owner may justify engineering a solution to:

1. harden their reliability, i.e. make a hard dependency a soft dependency
2. work with a lawyer to lessen an SLA (... not always possible ...)

To calculate the decision space of n-order constraints we will construct a directed, acyclical graph with all known information about the distrubuted system (hard dependencies, soft dependencies, SLAs, general truths) and then dynamically adjust based on chosen SLOs. 

***