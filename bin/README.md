# Heroku `bin` Directory

Reference: https://jtway.co/deploying-subdirectory-projects-to-heroku-f31ed65f3f2.

This directory provides the interface for a Heroku buildpack so that we can deploy the `test`
project as a standalone Rails application. This requires that our primary buildpack in Heroku be
defined as the inline buildpack: https://github.com/heroku/heroku-buildpack-inline.git.
