---
- hosts: localhost
  gather_facts: False
  vars:
    kerberos_user: 
    aws_region: 
  tasks:

  - name: Get access key
    shell: cat ~/.aws/credentials | grep aws_access_key_id | awk '{print $3}'
    register: access_key

  - name: Get access key
    shell: cat ~/.aws/credentials | grep aws_secret_access_key | awk '{print $3}'
    register: secret

  - name: Set environment
    set_fact:
      ec2_access_key: "{{ access_key.stdout }}"
      ec2_secret_key: "{{ secret.stdout }}"

  - name: Gather information about user's images
    ec2_ami_info:
      filters:
        "tag:user": "{{ kerberos_user }}"
    register: images

  - name: Tag old images
    ec2_tag:
      region: "{{ aws_region }}"
      resource: "{{ item.image_id }}"
      state: present
      tags:
        version: old
    with_items: "{{ images.images }}"

  - name: Copy user's images
    ec2_ami_copy:
      source_region: "{{ aws_region }}"
      region: "{{ aws_region }}"
      source_image_id: "{{ item.image_id }}"
      name: "{{ item.name }}"
      tags: '{"user":"{{ kerberos_user }}","version":"new"}'
    with_items: "{{ images.images }}"

  - name: Gather information about user's images
    ec2_ami_info:
      filters:
        "tag:version": old
        "tag:user": "{{ kerberos_user }}"
    register: old_images

  - name: Delete old images
    ec2_ami:
      image_id: "{{ item.image_id }}"
      delete_snapshot: False
      tags:
        version: old
      state: absent
    with_items: "{{ old_images.images }}"
