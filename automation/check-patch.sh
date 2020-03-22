#!/bin/bash -xe

# remove any previous artifacts
rm -rf output
rm -f ./*tar.gz

# Get the tarball
./build.sh dist

# create the src.rpm
rpmbuild \
    -D "_srcrpmdir $PWD/output" \
    -D "_topmdir $PWD/rpmbuild" \
    -ts ./*.gz

# install any build requirements
yum-builddep output/*src.rpm

# create the rpms
rpmbuild \
    -D "_rpmdir $PWD/output" \
    -D "_topmdir $PWD/rpmbuild" \
    --rebuild output/*.src.rpm

[[ -d exported-artifacts ]] || mkdir -p exported-artifacts
find output -iname \*rpm -exec mv "{}" exported-artifacts/ \;
mv *.tar.gz exported-artifacts

yum install $PWD/output/*.rpm
cd "/usr/share/ansible/collections/ansible_collections/ovirt/ovirt_collection"
ansible-test sanity --test validate-modules
ansible-test sanity --test pep8
ansible-test sanity --test pylint
