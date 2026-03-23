# Multiple Queues (MQ)

This repository contains the FPGA implementation of the Multiple Queues (MQ) architecture presented in our paper:

> Designing Multiple Queues to Support Asynchronous Traffic Shaping in Shared-Buffer TSN Switches
> (IEEE TCAD 2026)

MQ realizes Asynchronous Traffic Shaping (ATS) queues as metadata-driven logical queues on top of a shared-buffer switch architecture.

## Key Features

- Virtual queues implemented with lightweight head/tail pointers
- Centralized Multiple Queues Manager for enqueue/dequeue control
- Shift-register–based scheduler
- Full compatibility with IEEE 802.1Qcr ATS eligibility time computation

## Architecture

<figure>
  <img src="image/Design overview.svg" alt="MQ architecture overview on a shared-buffer switch" width="600">
  <figcaption>Figure 1. Design overview.</figcaption>
</figure>

<figure>
  <img src="image/MQ planes structure.svg" alt="Structure of MQ planes" width="600">
  <figcaption>Figure 2. MQ planes structure.</figcaption>
</figure>

## License

Released under the MIT License.

## References

```bibtex
@article{MQ_TCAD_2026,
  author  = {<Wenxue Wu, Tong Zhang, Zhen Li, Liwei Zhang, Hao Yang, and Fengyuan Ren>},
  title   = {Designing Multiple Queues to Support Asynchronous Traffic Shaping in Shared-Buffer TSN Switches},
  journal = {IEEE Transactions on Computer-Aided Design of Integrated Circuits and Systems},
  year    = {2026},
  volume  = {<卷>},
  number  = {<期>},
  pages   = {<起止页>},
  doi     = {<DOI>},
  url     = {<URL>}
}
```

