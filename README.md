# toodoo

Magit like interface for a simple Todo workflow built on top of Org.
(Assumes use of Evil Mode - a restriction that should be easy enough to relax.)

## Workflow

The package serves a simple opinionated Todo management workflow described below.

There are 3 categories of tasks:
1. Today - immediate items to be done in the next 8 hours
2. This Week - current context of items to be kept in mind for this week
3. Later - all other items

By default, only the immediate tasks should be shown to the user. Tasks can be created in any category and moved between them freely. Optionally, tasks can be marked as high priority. Periodically, completed tasks can be archived. (Not immediately after being marked DONE, since you want to see the list of tasks completed that day.)

The aim of the workflow is **simplicity** and **ease of use**. I did manage this with Org-mode, but the process was clunky.

## Design Philosophy

1. Not all of `org-mode`'s features are needed to manage tasks. They are handy, in general, for notes and the like, but for the workflow, they were getting in the way. At the same time, we can build on those so that we don't re-invent anything.
2. `org-agenda` is a powerful dashboard for tasks. But, I don't want a dashboard, I need the actual tasks, right there. The philosophy is, **the view of the thing should not be different from the actual underlying thing**.
3. Fast and easy access interface. There is only one solution for this: transients from magit.

## Acknowledgements

- How to make an Emacs Minor Mode: https://nullprogram.com/blog/2013/02/06/
