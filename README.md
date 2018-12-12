# Providing developers and testers with a representative database using Docker

When developing or testing, having a database that comes pre-filled with relevant data can be a big help with implementation or scenario walkthroughs. 
However, often there is only a structure dump of the production database available, or less. 
This article outlines the process of creating a Docker image that starts a database and automatically restores a dump containing a representative set of data. 
We use the PostgreSQL database in our examples, but the process outlined here can easily be applied to other databases such as MySQL or Oracle SQL.

#### Dumping the database  
I will assume that you have access to a database that contains a copy of production or an equivalent representative set of data. 
You can dump your database using Postgres' `pg_dump` utility:  
`pg_dump --dbname=postgresql://user@localhost:5432/mydatabase --format=custom --file=database.dmp`  

We will be using the `custom` format option to create the dump file with. This gives us a file that can easily be restored with the `pg_restore` utility later on and ensures the file is compressed. 
In case of larger databases, you may also wish to exclude certain database elements from your dump. In order to do so you have the following options:   

* The `--exclude-table` option, which takes a string pattern and ensures any tables matching the pattern will not be included in the dump file. 
* The `--schema` option, which restricts our dump to particular schemas in the database. It may be a good idea to exclude `pg_catalog` - this schema contains among other things the table `pg_largeobject`, which contains all of your database's binaries.    

See the [Postgres documentation][1] for more available options.

#### Distributing the dump among users 

For the distribution of the dump, we will be using Docker. 
[Postgres][2], [MySQL][3] and even [Oracle][4] provide you with prebuilt Docker images of their databases.   

**Example 1: A first attempt**  
In order to start an instance of a Postgres database, you can use the following `docker run` command to start a container based on Postgres:  
`docker run -p 5432:5432 --name database-dump-container -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password -e POSTGRES_DB=mydatabase -d postgres:9.5.10-alpine`

This starts a container named `database-dump-container` that can be reached at port 5432 with `user:password` as the login.
Note the usage of the `9.5.10-alpine` tag. This ensures that the Linux distribution that we use inside the Docker container is [Alpine Linux][5], a distribution with a small footprint. 
The whole Docker image will take up about 14 MB, while the regular `9.5.10` tag would require 104 MB. 
We are pulling the image from [Docker Hub][6], a public Docker registry where various open source projects host their Docker images.

Having started our Docker container, we can now copy our dump file into it. We first use `docker exec` to execute a command against the container we just made. 
In this case, we create a directory inside the Docker container:    
`docker exec -i database-dump-container mkdir -p /var/lib/postgresql/dumps/`  

Following that, we use `docker cp` to copy the dump file from our host into the container:  
`docker cp database.dmp database-dump-container:/var/lib/postgresql/dumps/`

After this, we can restore our dump:  	
`docker exec -i database-dump-container pg_restore --username=user --verbose --exit-on-error --format=custom --dbname=mydatabase /var/lib/postgresql/dumps/database.dmp`

We now have a Docker container with a running Postgres instance containing our data dump. In order to actually distribute this, you will need to get it into a Docker repository.
If you register with [Docker Hub][7] you can create [public repositories][8] for free. 
After creating your account you can login to the registry that hosts your repositories with the following command:   
`docker login docker.io`  

Enter the username and password for your Docker Hub account when prompted.    

Having done this, we are able to publish our data dump container as an image, using the following commands:   
`docker commit database-dump-container my-repository/database-dump-image`  
`docker push my-repository/database-dump-image`  

Note that you are able to push different versions of an image by using [Docker image tags][9]. 

The image is now available to other developers. It can be pulled and ran on another machine using the following commands:  
`docker pull my-repository/database-dump-image`  
`docker run -p 5432:5432 --name database-dump-container -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password -e POSTGRES_DB=mydatabase -d my-repository/database-dump-image`  

All done! Or are we? After we run the container based on the image, we still have an empty database. How did this happen?

**Example 2: Creating your own Dockerfile**  
It turns out that the Postgres Docker image uses [Docker volumes][10]. This separates the actual image from data and ensures that the size of the image remains reasonable. 
We can view what volumes Docker has made for us by using `docker volume ls`. 
These volumes can be associated with more than one Docker container and will remain, even after you have removed the container that initially spawned the volume.
If you would like to remove a Docker container, including its volumes, make sure to use the `-v` option:  
`docker rm -v database-dump-container`  

Go ahead and execute the command, we will be recreating the container in the following steps.  

So how can we use this knowledge to distribute our database _including_ our dump? Luckily, the Postgres image provides for exactly this situation.
Any scripts that are present in the Docker container under the directory `/docker-entrypoint-initdb.d/` will be executed automatically upon starting a new container.
This allows us to add data to the Docker volume upon starting the container.
In order to make use of this functionality, we are going to have to create our own image using a [Dockerfile][11] that extends the `postgres:9.5.10-alpine` image we used earlier:

    FROM postgres:9.5.10-alpine
    
    RUN mkdir -p /var/lib/postgresql/dumps/
    ADD database.dmp /var/lib/postgresql/dumps/
    ADD intialize.sh /docker-entrypoint-initdb.d/  

The contents of `initialize.sh` are as follows:  
`pg_restore --username=user --verbose --exit-on-error --format=custom --dbname=mydatabase /var/lib/postgresql/dumps/database.dmp`

We can build and run this Dockerfile by navigating to its directory and then executing:  
`docker build --rm=true -t database-dump-image .`  
`docker run -p 5432:5432 --name database-dump-container -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password -e POSTGRES_DB=mydatabase -d database-dump-image`

After starting the container, inspect its progress using `docker logs -f database-dump-container`. You can see that upon starting the container, our database dump is being restored into the Postgres instance.

We can now again publish the image using the earlier steps, and the image is available for usage. 

#### Conclusions and further reading

While working through this article, you have used a lot of important concepts within Docker. 
The first example demonstrated the usage of images and containers, combined with commands `exec` and `cp` that are able to interact with running containers. 
We then demonstrated how you can publish a Docker image using Docker Hub, after which we've shown you how to build and run your own custom made image.
We have also touched upon some more complex topics such as Docker volumes.  

After this you may wish to consult the [Docker documentation][12] to further familiarize yourself with the other commands that Docker offers.  
This setup still leaves room for improvement - the current process involves quite a lot of handwork, and we've coupled our container with one particular database dump. 
Please refer to the [Github project][13] for automated examples of this process.

 [1]: https://www.postgresql.org/docs/9.5/static/app-pgdump.html
 [2]: https://store.docker.com/images/postgres
 [3]: https://store.docker.com/images/mysql
 [4]: https://store.docker.com/images/oracle-database-enterprise-edition
 [5]: https://alpinelinux.org/about
 [6]: https://hub.docker.com/_/postgres/
 [7]: https://hub.docker.com/
 [8]: https://hub.docker.com/add/repository
 [9]: https://docs.docker.com/engine/reference/commandline/image_tag/
 [10]: https://docs.docker.com/engine/admin/volumes/volumes
 [11]: https://docs.docker.com/engine/reference/builder/
 [12]: https://docs.docker.com/
 [13]: https://github.com/markkrijgsman/postgres-docker